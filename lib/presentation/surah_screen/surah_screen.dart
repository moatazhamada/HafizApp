import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for RenderParagraph
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:hafiz_app/presentation/surah_screen/voice_verification_service.dart';
import 'package:hafiz_app/presentation/surah_screen/qrc_recitation_service.dart';
import 'package:hafiz_app/presentation/surah_screen/sheikh_audio_coach_sheet.dart';
import 'package:hafiz_app/presentation/surah_screen/custom_asr_service.dart';
import 'package:hafiz_app/presentation/surah_screen/local_whisper_service.dart';

import '../../core/app_export.dart';
import '../../core/qiraat/qiraat_service.dart';
import '../../core/quran_index/quran_surah.dart';

import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import 'bloc/surah_bloc.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/surah_name_formatter.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final surahBloc = sl<SurahBloc>();
  Surah? surah;

  // Scroll management
  ScrollController? _scrollControllerForInit;
  ScrollController get _scrollController => _scrollControllerForInit!;
  double? initialOffset;
  Timer? _offsetSaveDebounce;

  // Hifz Mode State
  bool _isHifzMode = false;
  final Set<int> _revealedVerses = {};
  int? _selectedVerse; // For visual selection feedback
  int? _highlightedVerse; // Verse to highlight and scroll to

  // Scroll Keys
  final Map<int, GlobalKey> _verseKeys = {};
  final Map<int, GlobalKey> _richTextVerseKeys = {};
  List<_VerseRange> _currentVerseRanges = [];

  // Voice Verification
  final VoiceVerificationService _voiceService = VoiceVerificationService();
  final QiraatService _qiraatService = QiraatService();
  bool _isListening = false;
  int _sessionCorrectCount = 0;
  int _sessionTotalCount = 0;

  // Key for accurate hit testing on RichText with WidgetSpans
  final GlobalKey _richTextKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Logic moved to didChangeDependencies to safely access ModalRoute
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scrollControllerForInit == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Surah) {
        surah = args;
      } else if (args is Map) {
        surah = args['surah'] as Surah?;

        final vIndex = args['verseIndex'];
        if (vIndex is int) {
          // Prefer verseIndex for precise scrolling - don't use offset
          _selectedVerse = vIndex + 1;
          _highlightedVerse = vIndex + 1;
        } else {
          // Use offset only when verseIndex is not provided
          final off = args['offset'];
          if (off is num) initialOffset = off.toDouble();
        }
      }

      if (surah != null) {
        surahBloc.add(LoadSurahEvent(surahId: surah?.id.toString() ?? ''));
      }

      _scrollControllerForInit = ScrollController(
        initialScrollOffset: initialOffset ?? 0,
      );
      _scrollControllerForInit!.addListener(() {
        if (surah == null) return;

        _offsetSaveDebounce?.cancel();
        _offsetSaveDebounce = Timer(const Duration(milliseconds: 350), () {
          if (!mounted || surah == null) return;
          PrefUtils().setSurahOffset(
            surah!.id,
            _scrollControllerForInit!.offset,
          );
        });
      });
    }
  }

  void _scrollToVerseWithRetry(
    int verseNumber,
    List<Verse> chapters, {
    int attempt = 0,
  }) {
    // Attempt 0: Check if transition is happening
    if (attempt == 0) {
      final route = ModalRoute.of(context);
      if (route is TransitionRoute) {
        final animation = route?.animation;
        if (animation != null &&
            animation.status != AnimationStatus.completed) {
          // Wait for transition to finish
          void handler(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              animation.removeStatusListener(handler);
              if (mounted) {
                _scrollToVerseWithRetry(verseNumber, chapters, attempt: 0);
              }
            }
          }

          animation.addStatusListener(handler);
          return;
        }
      }
    }

    // Max 20 attempts (~4 seconds total) for layout/rendering
    if (attempt > 20) return;

    // Standard short delay for layout retry (200ms)
    // No initial long delay needed since we waited for transition
    int delay = 200;

    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      bool success = _scrollToVerse(verseNumber, chapters);
      if (!success) {
        _scrollToVerseWithRetry(verseNumber, chapters, attempt: attempt + 1);
      } else {
        // Clear highlight after success + delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _highlightedVerse = null;
            });
          }
        });
      }
    });
  }

  /// Returns true if scroll was initiated successfully
  bool _scrollToVerse(int verseNumber, List<Verse> chapters) {
    if (PrefUtils().getVerseViewMode()) {
      // Single Line Mode - use GlobalKey
      final key = _verseKeys[verseNumber];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15, // Align slightly below top
        );
        return true;
      }
      return false; // Key not ready
    } else {
      // Mushaf/RichText Mode - prefer anchor keys for reliability
      final anchorKey = _richTextVerseKeys[verseNumber];
      if (anchorKey != null && anchorKey.currentContext != null) {
        Scrollable.ensureVisible(
          anchorKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return true;
      }

      // Fallback: RenderParagraph based scroll
      final RenderObject? renderObject = _richTextKey.currentContext
          ?.findRenderObject();

      if (renderObject is RenderParagraph && _currentVerseRanges.isNotEmpty) {
        // Find the verse range
        final verseRange = _currentVerseRanges.firstWhere(
          (r) => r.verse.verseNumber == verseNumber && !r.isBadge,
          orElse: () => _currentVerseRanges.first,
        );

        try {
          final boxes = renderObject.getBoxesForSelection(
            TextSelection(
              baseOffset: verseRange.start,
              extentOffset: verseRange.start + 1,
            ),
          );

          if (boxes.isNotEmpty && _scrollController.hasClients) {
            final boxTop = boxes.first.top;
            // Calculate absolute position on screen
            final globalOffset = renderObject.localToGlobal(Offset(0, boxTop));

            // Current scroll offset
            final currentScroll = _scrollController.offset;

            // Desired position on screen (e.g. 140px from top, below AppBar)
            const double targetScreenY = 140.0;

            // Calculate delta needed to move globalOffset.dy to targetScreenY
            final delta = globalOffset.dy - targetScreenY;

            // Calculate new scroll position
            final targetScroll = (currentScroll + delta).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            );

            _scrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            return true;
          }
        } catch (e) {
          debugPrint('Scroll error: $e');
          return false;
        }
      }
      return false;
    }
  }

  void _saveReadingProgress() {
    if (surah == null) return;

    // 1. Always ensure this Surah is marked as the last read one
    PrefUtils().saveLastReadSurah(surah!);

    // 2. Find the top visible verse to save specific position
    int? visibleVerseNumber;

    if (PrefUtils().getVerseViewMode()) {
      // Single Line Mode: Check GlobalKeys
      // Heuristic: iterate keys, find first one with positive offset relative to viewport
      // or closest to 0.
      for (var entry in _verseKeys.entries) {
        final key = entry.value;
        if (key.currentContext != null) {
          final RenderBox? box =
              key.currentContext!.findRenderObject() as RenderBox?;
          if (box != null) {
            final position = box.localToGlobal(Offset.zero);
            // 70 is rough app bar height+padding offset
            if (position.dy >= 0 &&
                position.dy < MediaQuery.of(context).size.height / 2) {
              visibleVerseNumber = entry.key;
              break;
            }
          }
        }
      }
    } else {
      // Mushaf/RichText Mode
      final RenderObject? renderObject = _richTextKey.currentContext
          ?.findRenderObject();
      if (renderObject is RenderParagraph && _currentVerseRanges.isNotEmpty) {
        // We need to find which range is at the current scroll offset.
        // It's hard to inverse-map generic text spans easily without coordinates.
        // But we can check our known ranges.

        // Strategy: Check middle of the screen text offset?
        // Or check dynamic boxes of ranges? Checking 200+ ranges might be acceptable.

        // Optimization: Binary search or check only ranges likely to be visible?
        // Let's simplified check: Find first range whose box bottom > 0 (relative to viewport)
        // We really need viewport relative coordinates.

        try {
          // We can't easily get viewport relative rects for ALL ranges efficiently.
          // Fallback: Use the scroll offset + heuristic
          // If we have scroll offset, we know we are at N pixels down.
          // But text height is variable.

          // Better approach for Mushaf: _currentVerseRanges contains all verses.
          // We can sample a few points on screen (e.g. top-left content area) and hit-test.

          // Hit testing via renderObject.getPositionForOffset
          // Offset(0, 0) in the renderParagraph is the very top.
          // The renderParagraph is inside the ScrollView.
          // We know the scroll offset.
          // So, the top visible text is at local offset = (0, _scrollController.offset).
          // Add a small buffer (e.g. 50px) to skip empty space.

          if (_scrollController.hasClients) {
            // getPositionForOffset expects local coordinates within RenderParagraph.
            final Size size = renderObject.size;
            final Offset targetLcOffset = Offset(
              20,
              (20.0).clamp(0.0, (size.height - 1).clamp(0.0, double.infinity)),
            );
            final textPosition = renderObject.getPositionForOffset(
              targetLcOffset,
            );
            final textOffset = textPosition.offset;

            // Find range containing this text offset
            final range = _currentVerseRanges.firstWhere(
              (r) => textOffset >= r.start && textOffset < r.end,
              orElse: () => _currentVerseRanges.first,
            );

            visibleVerseNumber = range.verse.verseNumber;
          }
        } catch (_) {
          // ignore
        }
      }
    }

    if (visibleVerseNumber != null) {
      PrefUtils().setSurahVerseIndex(surah!.id, visibleVerseNumber - 1);
    }
  }

  @override
  void dispose() {
    _offsetSaveDebounce?.cancel();
    _voiceService.stop();
    _isListening = false;
    _scrollControllerForInit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PrefUtils().getIsDarkMode();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(isDark == true ? 0xFF000000 : 0xFFFFFFFF),
        body: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            _saveReadingProgress();
            // Allow pop to proceed
          },
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SurahBloc>(create: (context) => surahBloc),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<BookmarkBloc, BookmarkState>(
                  listener: (context, state) {
                    if (state is BookmarkLoaded &&
                        state.feedbackMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.feedbackMessage!.tr),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                BlocListener<RecitationErrorBloc, RecitationErrorState>(
                  listener: (context, state) {
                    if (state is RecitationErrorLoaded &&
                        state.feedbackMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.feedbackMessage!.tr),
                          backgroundColor: Colors.red[700],
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
              child: BlocBuilder<SurahBloc, SurahState>(
                builder: (context, state) {
                  if (state is LoadingSurahState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FailureSurahState) {
                    return Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(state.errorMessage),
                      ),
                    );
                  } else {
                    final chapters = (state as SuccessSurahState).chapters;
                    // Trigger scroll if selectedVerse is set and not scrolled yet
                    if (_selectedVerse != null && chapters.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedVerse != null) {
                          _scrollToVerseWithRetry(_selectedVerse!, chapters);
                          _selectedVerse = null; // Clear to avoid re-scrolling
                        }
                      });
                    }

                    return BlocBuilder<BookmarkBloc, BookmarkState>(
                      builder: (context, bookmarkState) {
                        return BlocBuilder<
                          RecitationErrorBloc,
                          RecitationErrorState
                        >(
                          builder: (context, errorState) {
                            return CustomScrollView(
                              controller: _scrollController,
                              slivers: [
                                _buildSliverAppBar(isDark),
                                SliverPadding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 20.v,
                                  ),
                                  sliver: _buildSurahList(
                                    context,
                                    chapters,
                                    bookmarkState,
                                    errorState,
                                    isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF006754),
      leading: Semantics(
        button: true,
        label: 'lbl_back'.tr,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => NavigatorService.goBack(),
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: 'lbl_help'.tr,
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => NavigatorService.pushNamed(AppRoutes.helpScreen),
          ),
        ),
        Semantics(
          button: true,
          label: _isHifzMode ? 'lbl_exit_hifz_mode'.tr : 'lbl_hifz_mode'.tr,
          child: IconButton(
            icon: Icon(
              _isHifzMode ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isHifzMode = !_isHifzMode;
                _revealedVerses.clear();
              });
              // Announce mode change for accessibility
              // ignore: deprecated_member_use
              SemanticsService.announce(
                _isHifzMode ? 'lbl_hifz_mode_on'.tr : 'lbl_hifz_mode_off'.tr,
                TextDirection.ltr,
              );
            },
          ),
        ),
        BlocBuilder<BookmarkBloc, BookmarkState>(
          builder: (context, state) {
            bool isBookmarked = false;
            if (state is BookmarkLoaded) {
              isBookmarked = state.bookmarks.any(
                (element) => element.surahId == (surah?.id ?? -1),
              );
            }
            return Semantics(
              button: true,
              label: isBookmarked
                  ? 'lbl_remove_bookmark'.tr
                  : 'lbl_add_bookmark'.tr,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (surah == null) return;
                  if (isBookmarked) {
                    context.read<BookmarkBloc>().add(
                      RemoveBookmarkEvent(surah!.id, 1),
                    );
                  } else {
                    context.read<BookmarkBloc>().add(
                      AddBookmarkEvent(
                        BookmarkModel(
                          surahId: surah!.id,
                          surahName: surah!.nameEnglish,
                          verseNumber: 1,
                          createdAt: DateTime.now(),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            // Increased padding to prevent overlap with action icons (3 icons * 48 = 144 + margin)
            padding: const EdgeInsets.symmetric(horizontal: 146.0),
            child: Semantics(
              header: true,
              child: Text(
                surah?.localizedName(context) ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Amiri',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -55,
              bottom: -10,
              child: ExcludeSemantics(
                child: CustomImageView(
                  fit: BoxFit.cover,
                  imagePath: ImageConstant.imgQuranOnboarding,
                  height: 150.v,
                  width: 150.h,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF006754), Color(0xDB87D1A4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBismillah(bool isDark) {
    if (surah?.id == 1 || surah?.id == 9) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'lbl_bismillah'.tr,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF004B40),
          ),
        ),
      ),
    );
  }

  void _showVerseMenu(
    BuildContext context,
    Verse aya,
    bool isBookmarked,
    bool isError,
  ) {
    if (surah == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Semantics(
              button: true,
              label: isBookmarked
                  ? 'lbl_remove_bookmark'.tr
                  : 'lbl_add_bookmark'.tr,
              child: ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                  color: Colors.teal,
                ),
                title: Text(
                  isBookmarked
                      ? 'lbl_remove_bookmark'.tr
                      : 'lbl_add_bookmark'.tr,
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isBookmarked) {
                    context.read<BookmarkBloc>().add(
                      RemoveBookmarkEvent(surah!.id, aya.verseNumber),
                    );
                  } else {
                    context.read<BookmarkBloc>().add(
                      AddBookmarkEvent(
                        BookmarkModel(
                          surahId: surah!.id,
                          surahName: surah!.nameEnglish,
                          verseNumber: aya.verseNumber,
                          createdAt: DateTime.now(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Semantics(
              button: true,
              label: isError
                  ? 'msg_unmark_practice'.tr
                  : 'msg_mark_practice'.tr,
              child: ListTile(
                leading: Icon(
                  isError ? Icons.playlist_remove : Icons.error_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  isError ? 'msg_unmark_practice'.tr : 'msg_mark_practice'.tr,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isError) {
                    context.read<RecitationErrorBloc>().add(
                      RemoveRecitationErrorEvent(surah!.id, aya.verseNumber),
                    );
                  } else {
                    context.read<RecitationErrorBloc>().add(
                      AddRecitationErrorEvent(
                        RecitationErrorModel(
                          surahId: surah!.id,
                          surahName: surah!.nameEnglish,
                          verseId: aya.verseNumber,
                          createdAt: DateTime.now(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Semantics(
              button: true,
              label: 'lbl_verify_recitation'.tr,
              child: ListTile(
                leading: const Icon(Icons.mic, color: Colors.blueAccent),
                title: Text('lbl_verify_recitation'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceDialog(context, aya);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceDialog(BuildContext context, Verse aya) async {
    final parentContext = context;
    // 1. Request Permission Lazy
    bool available = await _voiceService.requestPermission();
    if (!available) {
      if (context.mounted) {
        // Show Dialog to guide user to settings
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('msg_mic_permission'.tr),
            content: Text(
              'msg_mic_permission_desc'.tr,
            ), // We might need to add this key or just use generic text
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('lbl_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('lbl_settings'.tr),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Prepare Expectation (Strip Bismillah)
    String expectedText = await _resolveExpectedText(aya);
    if (aya.verseNumber == 1 && surah?.id != 1) {
      const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
      const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
      if (expectedText.startsWith(bismillahPrefix)) {
        expectedText = expectedText.substring(bismillahPrefix.length).trim();
      } else if (expectedText.startsWith(bismillahSimple)) {
        expectedText = expectedText.substring(bismillahSimple.length).trim();
      }
    }

    final provider = PrefUtils().getRecitationProvider();
    final bool useQrc = provider == 'qrc';
    final bool useCustom = provider == 'custom';
    final bool useWhisper = provider == 'local_whisper';
    final String customEndpoint = PrefUtils().getCustomAsrEndpoint();
    String spokenText = 'lbl_listening'.tr;
    Color statusColor = Colors.blueAccent;
    bool hasStartedListening = false;
    String feedbackTitle = '';
    String scoreText = '';
    String hintLabel = '';
    String hintWord = '';
    List<String> issueLines = [];
    bool showFeedback = false;
    String qrcStatus = '';
    int qrcWordIndex = 0;
    List<QrcTajweedMistake> qrcMistakes = [];
    List<String> qrcMistakeLines = [];
    String repeatLabel = '';
    String repeatWord = '';
    bool qrcConnecting = false;
    StreamSubscription? qrcSub;
    final qrcService = QrcRecitationService();
    final customAsrService = CustomAsrService();
    final customRecorder = FlutterSoundRecorder();
    String? customFilePath;
    final whisperService = LocalWhisperService();
    bool whisperTranscribing = false;

    if (!mounted) return;

    // Stop any existing session before showing dialog to be safe
    await _voiceService.stop();
    _isListening = false;

    bool autoAdvanced = false;

    if (!parentContext.mounted) return;
    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Function to start listening
            void startListening() async {
              if (!_isListening) {
                _isListening = true;
                hasStartedListening = true;
                setDialogState(() {
                  statusColor = Colors.blueAccent;
                  spokenText = 'lbl_listening'.tr;
                });
                if (useQrc) {
                  setDialogState(() {
                    qrcConnecting = true;
                    qrcStatus = 'lbl_connecting'.tr;
                  });
                  final connected = await qrcService.connect();
                  if (!connected) {
                    setDialogState(() {
                      statusColor = Colors.redAccent;
                      feedbackTitle = 'msg_qrc_missing_key'.tr;
                      qrcConnecting = false;
                      showFeedback = true;
                      _isListening = false;
                    });
                    return;
                  }

                  qrcSub = qrcService.events.listen((event) {
                    if (!mounted) return;
                    if (event is QrcStatusEvent) {
                      setDialogState(() {
                        qrcStatus = event.status;
                        if (event.status == 'connected' ||
                            event.status == 'check_tilawa' ||
                            event.status == 'CheckTilawaResponse') {
                          qrcConnecting = false;
                        }
                      });
                    } else if (event is QrcCheckEvent) {
                      final data = event.data;
                      setDialogState(() {
                        qrcWordIndex = data.wordIndex ?? qrcWordIndex;
                        qrcMistakes = data.tajweedMistakes;
                        qrcMistakeLines = qrcMistakes
                            .map((m) =>
                                '${m.name ?? 'Tajweed'} (${m.wordIndex ?? '-'})')
                            .toList();
                        showFeedback = true;
                        final expectedTokens = expectedText
                            .split(RegExp(r'\s+'))
                            .where((t) => t.isNotEmpty)
                            .toList();
                        final expectedCount = expectedTokens.length;
                        final progress = expectedCount == 0
                            ? 0
                            : ((qrcWordIndex / expectedCount) * 100).round();
                        scoreText =
                            '${'lbl_recitation_score'.tr}: $progress%';
                        issueLines = [];
                        if (qrcMistakes.isNotEmpty) {
                          issueLines.add(
                            '${'msg_tajweed_notes'.tr}: ${qrcMistakes.length}',
                          );
                        }
                        repeatLabel = '';
                        repeatWord = '';
                        if (qrcMistakes.isNotEmpty &&
                            (qrcMistakes.first.wordIndex ?? 0) > 0) {
                          final idx = (qrcMistakes.first.wordIndex ?? 1) - 1;
                          if (idx >= 0 && idx < expectedTokens.length) {
                            repeatLabel = 'msg_repeat_word'.tr;
                            repeatWord = expectedTokens[idx];
                          }
                        } else if (qrcWordIndex < expectedCount) {
                          repeatLabel = 'msg_repeat_word'.tr;
                          repeatWord = expectedTokens[qrcWordIndex];
                        }
                        if (qrcWordIndex >= expectedCount &&
                            expectedCount > 0 &&
                            qrcMistakes.isEmpty) {
                          statusColor = Colors.green;
                          feedbackTitle = 'lbl_congrats'.tr;
                          unawaited(Future.delayed(
                              const Duration(milliseconds: 1000), () {
                            if (mounted &&
                                dialogContext.mounted &&
                                Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                              _onRecitationCorrect(aya);
                            }
                          }));
                        }
                      });
                    } else if (event is QrcErrorEvent) {
                      setDialogState(() {
                        statusColor = Colors.redAccent;
                        feedbackTitle = event.message;
                        showFeedback = true;
                      });
                    }
                  });

                  await qrcService.startTilawaSession(
                    surahIndex: surah!.id,
                    verseIndex: aya.verseNumber,
                    hafzLevel: PrefUtils().getQrcHafzLevel(),
                    tajweedLevel: PrefUtils().getQrcTajweedLevel(),
                  );
                  await qrcService.startRecording();
                } else if (useWhisper) {
                  await customRecorder.openRecorder();
                  final dir = await getTemporaryDirectory();
                  customFilePath =
                      '${dir.path}/whisper_${surah!.id}_${aya.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.wav';
                  await customRecorder.startRecorder(
                    toFile: customFilePath,
                    codec: Codec.pcm16WAV,
                    numChannels: 1,
                    sampleRate: 16000,
                  );
                  setDialogState(() {
                    spokenText = 'lbl_listening'.tr;
                  });
                } else {
                  if (useCustom) {
                    if (customEndpoint.isEmpty) {
                      setDialogState(() {
                        statusColor = Colors.orangeAccent;
                        feedbackTitle = 'msg_custom_asr_empty'.tr;
                        showFeedback = true;
                      });
                    } else {
                      await customRecorder.openRecorder();
                      final dir = await getTemporaryDirectory();
                      customFilePath =
                          '${dir.path}/recite_${surah!.id}_${aya.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.wav';
                      await customRecorder.startRecorder(
                        toFile: customFilePath,
                        codec: Codec.pcm16WAV,
                        numChannels: 1,
                        sampleRate: 16000,
                      );
                    }
                  }

                  await _voiceService.listen(
                    onResult: (text) {
                    if (!dialogContext.mounted) return;
                      setDialogState(() {
                        spokenText = text;
                      });
                    },
                    onDone: (finalText) async {
                      _isListening = false;
                      if (!dialogContext.mounted) return;
                      String effectiveText = finalText;
                      if (useCustom &&
                          customEndpoint.isNotEmpty &&
                          customFilePath != null) {
                        try {
                          await customRecorder.stopRecorder();
                        } catch (_) {}
                        final remoteText = await customAsrService.transcribe(
                          endpoint: customEndpoint,
                          filePath: customFilePath!,
                        );
                        if (remoteText != null && remoteText.isNotEmpty) {
                          effectiveText = remoteText;
                        }
                      }
                      final analysis = _voiceService.analyzeRecitation(
                        effectiveText,
                        expectedText,
                        allowPartial: true,
                      );
                      setDialogState(() {
                        spokenText = effectiveText;
                        final scorePercent = (analysis.score * 100).round();
                        scoreText =
                            '${'lbl_recitation_score'.tr}: $scorePercent%';
                        issueLines = [];
                        if (analysis.missingCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_missing'.tr}: ${analysis.missingCount}',
                          );
                        }
                        if (analysis.extraCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_extra'.tr}: ${analysis.extraCount}',
                          );
                        }
                        if (analysis.substituteCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_substitute'.tr}: ${analysis.substituteCount}',
                          );
                        }

                        hintLabel = '';
                        hintWord = '';
                        repeatLabel = '';
                        repeatWord = '';
                        final expectedTokens = expectedText
                            .split(RegExp(r'\s+'))
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (analysis.expectedRange.isValid &&
                            analysis.expectedRange.start <
                                expectedTokens.length &&
                            !analysis.passed) {
                          hintLabel = 'msg_recitation_hint_start'.tr;
                          hintWord = expectedTokens[analysis.expectedRange.start];
                          repeatLabel = 'msg_repeat_word'.tr;
                          repeatWord = hintWord;
                        }

                        showFeedback = true;

                        if (analysis.isTooShort) {
                          statusColor = Colors.orangeAccent;
                          feedbackTitle = 'msg_recitation_too_short'.tr;
                          return;
                        }

                        if (analysis.passed) {
                          statusColor = Colors.green;
                          feedbackTitle = 'lbl_congrats'.tr;
                          // Auto Advance Delay
                          unawaited(Future.delayed(
                              const Duration(milliseconds: 1000), () {
                            if (mounted &&
                                dialogContext.mounted &&
                                Navigator.canPop(dialogContext)) {
                            autoAdvanced = true;
                              Navigator.pop(dialogContext);
                              _onRecitationCorrect(aya);
                            }
                          }));
                        } else {
                          statusColor = Colors.redAccent;
                          feedbackTitle = 'msg_incorrect_recitation'.tr;
                          // Show Wrong Dialog
                          unawaited(Future.delayed(
                              const Duration(milliseconds: 1000), () {
                            if (mounted &&
                                dialogContext.mounted &&
                                Navigator.canPop(dialogContext)) {
                            autoAdvanced = true;
                              Navigator.pop(dialogContext);
                            _showWrongDialog(parentContext, aya);
                            }
                          }));
                      }
                    });
                  },
                );
              }
            }
            }

            // Function to stop listening
            void stopListening() async {
              if (_isListening) {
                if (useQrc) {
                  await qrcService.stopRecording();
                  await qrcSub?.cancel();
                } else if (useWhisper) {
                  try {
                    await customRecorder.stopRecorder();
                  } catch (_) {}
                  if (customFilePath != null) {
                    setDialogState(() {
                      whisperTranscribing = true;
                      spokenText = 'msg_transcribing'.tr;
                    });
                    final transcribed = await whisperService.transcribe(
                      audioPath: customFilePath!,
                      language: 'ar',
                    );
                    setDialogState(() {
                      whisperTranscribing = false;
                    });
                    if (transcribed != null && transcribed.isNotEmpty) {
                      final analysis = _voiceService.analyzeRecitation(
                        transcribed,
                        expectedText,
                        allowPartial: true,
                      );
                      setDialogState(() {
                        spokenText = transcribed;
                        final scorePercent = (analysis.score * 100).round();
                        scoreText =
                            '${'lbl_recitation_score'.tr}: $scorePercent%';
                        issueLines = [];
                        if (analysis.missingCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_missing'.tr}: ${analysis.missingCount}',
                          );
                        }
                        if (analysis.extraCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_extra'.tr}: ${analysis.extraCount}',
                          );
                        }
                        if (analysis.substituteCount > 0) {
                          issueLines.add(
                            '${'msg_recitation_substitute'.tr}: ${analysis.substituteCount}',
                          );
                        }

                        hintLabel = '';
                        hintWord = '';
                        repeatLabel = '';
                        repeatWord = '';
                        final expectedTokens = expectedText
                            .split(RegExp(r'\s+'))
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (analysis.expectedRange.isValid &&
                            analysis.expectedRange.start <
                                expectedTokens.length &&
                            !analysis.passed) {
                          hintLabel = 'msg_recitation_hint_start'.tr;
                          hintWord = expectedTokens[analysis.expectedRange.start];
                          repeatLabel = 'msg_repeat_word'.tr;
                          repeatWord = hintWord;
                        }

                        showFeedback = true;

                        if (analysis.isTooShort) {
                          statusColor = Colors.orangeAccent;
                          feedbackTitle = 'msg_recitation_too_short'.tr;
                          return;
                        }

                        if (analysis.passed) {
                          statusColor = Colors.green;
                          feedbackTitle = 'lbl_congrats'.tr;
                          unawaited(Future.delayed(
                              const Duration(milliseconds: 1000), () {
                            if (mounted &&
                                dialogContext.mounted &&
                                Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                              _onRecitationCorrect(aya);
                            }
                          }));
                        } else {
                          statusColor = Colors.redAccent;
                          feedbackTitle = 'msg_incorrect_recitation'.tr;
                          unawaited(Future.delayed(
                              const Duration(milliseconds: 1000), () {
                            if (context.mounted &&
                                dialogContext.mounted &&
                                Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                              _showWrongDialog(context, aya);
                            }
                          }));
                        }
                      });
                    }
                  }
                } else if (useCustom) {
                  try {
                    await customRecorder.stopRecorder();
                  } catch (_) {}
                } else {
                  await _voiceService.stop();
                }
                _isListening = false;
                setDialogState(() {
                  statusColor = Colors.grey;
                  spokenText = 'msg_tap_to_resume'.tr;
                });
              }
            }

            // Auto-start on first build
            if (!hasStartedListening && !_isListening) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startListening();
              });
            }

            return AlertDialog(
              title: Semantics(
                header: true,
                child: Text('lbl_recite_verify'.tr),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: _isListening
                        ? 'msg_tap_to_stop'.tr
                        : 'lbl_tap_to_speak'.tr,
                    child: GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          stopListening();
                        } else {
                          startListening();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : Colors.blueAccent.withValues(alpha: 0.1),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          size: 48,
                          color: _isListening
                              ? Colors.redAccent
                              : Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!useQrc) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        spokenText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Amiri',
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _isListening ? 'msg_tap_to_stop'.tr : 'lbl_tap_to_speak'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (useQrc) ...[
                    const SizedBox(height: 12),
                    if (qrcConnecting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (qrcStatus.isNotEmpty)
                      Text(
                        qrcStatus,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: expectedText
                          .split(RegExp(r'\s+'))
                          .where((t) => t.isNotEmpty)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final idx = entry.key + 1;
                        final word = entry.value;
                        final isCorrect = qrcWordIndex >= idx;
                        final isMistake = qrcMistakes
                            .any((m) => m.wordIndex == idx);
                        Color color = Colors.black87;
                        if (isCorrect) color = Colors.green;
                        if (isMistake) color = Colors.redAccent;
                        return Text(
                          word,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Amiri',
                            color: color,
                            fontWeight: isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    if (qrcMistakeLines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final line in qrcMistakeLines)
                        Text(
                          line,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                    ],
                  ],
                  if (useWhisper && whisperTranscribing) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(strokeWidth: 2),
                  ],
                  if (showFeedback) ...[
                    const SizedBox(height: 12),
                    Text(
                      feedbackTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scoreText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (issueLines.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final line in issueLines)
                        Text(
                          line,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                    if (hintLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hintLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        hintWord,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                    if (repeatLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        repeatLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        repeatWord,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'msg_coach_tip_slow'.tr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    'lbl_original'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expectedText, // Display stripped text for verification context
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontFamily: 'Amiri'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: dialogContext,
                      builder: (_) => SheikhAudioCoachSheet(
                        chapterNumber: surah!.id,
                        verseNumber: aya.verseNumber,
                        expectedText: expectedText,
                        reciterId: PrefUtils().getReciterId(),
                      ),
                    );
                  },
                  child: Text('lbl_listen_sheikh'.tr),
                ),
                TextButton(
                  onPressed: () {
                    stopListening();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('lbl_close'.tr),
                ),
              ],
            );
          },
        );
      },
    );

    // Cleanup when dialog closes
    if (!autoAdvanced) {
      await _voiceService.stop();
      _isListening = false;
    await qrcSub?.cancel();
    await qrcService.dispose();
    try {
      await customRecorder.closeRecorder();
    } catch (_) {}
  }

  Future<String> _resolveExpectedText(Verse aya) async {
    if (surah == null) return aya.text;
    final edition = PrefUtils().getQiraatEdition();
    if (edition == 'quran-uthmani' || edition.isEmpty) {
      return aya.text;
    }
    final remoteText = await _qiraatService.fetchAyahText(
      surahId: surah!.id,
      verseNumber: aya.verseNumber,
      edition: edition,
    );
    return remoteText ?? aya.text;
    }
  }

  void _onRecitationCorrect(Verse currentVerse) {
    _sessionCorrectCount++;
    _sessionTotalCount++;

    // Find next verse
    final currentState = surahBloc.state;
    if (currentState is SuccessSurahState) {
      final chapters = currentState.chapters;
      final currentIndex = chapters.indexWhere(
        (v) => v.verseNumber == currentVerse.verseNumber,
      );

      if (currentIndex != -1 && currentIndex < chapters.length - 1) {
        // Next verse exists
        final nextVerse = chapters[currentIndex + 1];
        _showVoiceDialog(context, nextVerse);
      } else {
        // End of Surah
        _showCompletionDialog();
      }
    }
  }

  void _showWrongDialog(BuildContext parentContext, Verse aya) {
    _sessionTotalCount++;

    // Capture the bloc reference from parent context before showing dialog
    final recitationErrorBloc = parentContext.read<RecitationErrorBloc>();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('lbl_incorrect'.tr),
        content: Text('msg_incorrect_recitation'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Wait for pop to finish before opening new dialog
              Future.delayed(const Duration(milliseconds: 300), () {
                if (parentContext.mounted) {
                  _showVoiceDialog(parentContext, aya);
                }
              });
            },
            child: Text('lbl_try_again'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Mark for Practice Logic - use captured bloc reference
              recitationErrorBloc.add(
                AddRecitationErrorEvent(
                  RecitationErrorModel(
                    surahId: surah!.id,
                    surahName: surah!.nameEnglish,
                    verseId: aya.verseNumber,
                    createdAt: DateTime.now(),
                  ),
                ),
              );
              Navigator.pop(dialogContext);

              // Move to next
              final currentState = surahBloc.state;
              if (currentState is SuccessSurahState) {
                final chapters = currentState.chapters;
                final currentIndex = chapters.indexWhere(
                  (v) => v.verseNumber == aya.verseNumber,
                );
                if (currentIndex != -1 && currentIndex < chapters.length - 1) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (parentContext.mounted) {
                      _showVoiceDialog(
                        parentContext,
                        chapters[currentIndex + 1],
                      );
                    }
                  });
                } else {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (parentContext.mounted) _showCompletionDialog();
                  });
                }
              }
            },
            child: Text('lbl_save_practice'.tr),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    double percentage = 0;
    if (_sessionTotalCount > 0) {
      percentage = (_sessionCorrectCount / _sessionTotalCount) * 100;
    }

    if (percentage >= 50) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('lbl_congrats'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.celebration, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 16),
              Text(
                'msg_session_score'.tr.replaceAll(
                  '{score}',
                  percentage.toStringAsFixed(1),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sessionCorrectCount = 0;
                _sessionTotalCount = 0;
                Navigator.pop(context);
              },
              child: Text('lbl_close'.tr),
            ),
          ],
        ),
      );
    } else {
      // Maybe just close quietly or show a "Good effort"
      _sessionCorrectCount = 0;
      _sessionTotalCount = 0;
    }
  }

  Widget _buildSurahList(
    BuildContext context,
    List<Verse> chapters,
    BookmarkState bookmarkState,
    RecitationErrorState errorState,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBismillah(isDark),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrefUtils().getVerseViewMode()
                ? _buildSingleLineContent(
                    context,
                    chapters,
                    bookmarkState,
                    errorState,
                    isDark,
                  )
                : _buildRichTextContent(
                    context,
                    chapters,
                    bookmarkState,
                    errorState,
                    isDark,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextContent(
    BuildContext context,
    List<Verse> chapters,
    BookmarkState bookmarkState,
    RecitationErrorState errorState,
    bool isDark,
  ) {
    final Color textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF004B40);
    final Color badgeBorder = isDark
        ? const Color(0xFF87D1A4)
        : const Color(0xFF006754);
    final Color badgeText = isDark
        ? const Color(0xFFFAF6EB)
        : const Color(0xFF004B40);
    final List<Color> badgeGradient = isDark
        ? [const Color(0xFF113C35), const Color(0xFF0B2D28)]
        : [const Color(0xFFFAF6EB), const Color(0xFFEDE6D6)];

    List<InlineSpan> spans = [];
    final List<_VerseRange> verseRanges = [];
    int currentOffset = 0;

    // Reset current ranges for scroll logic
    _currentVerseRanges =
        verseRanges; // Will be populated by reference or re-assigned?
    // Actually we should assign at end, or use the local list and assign to member.
    // Let's rely on local list then assign.

    for (var aya in chapters) {
      bool isBookmarked = false;
      if (bookmarkState is BookmarkLoaded) {
        isBookmarked = bookmarkState.bookmarks.any(
          (b) =>
              b.surahId == (surah?.id ?? -1) &&
              b.verseNumber == aya.verseNumber,
        );
      }
      bool isRecitationError = false;
      if (errorState is RecitationErrorLoaded) {
        isRecitationError = errorState.errors.any(
          (m) => m.surahId == (surah?.id ?? -1) && m.verseId == aya.verseNumber,
        );
      }

      bool isBlurred =
          _isHifzMode && !_revealedVerses.contains(aya.verseNumber);
      bool isHighlighted = _highlightedVerse == aya.verseNumber;

      Color? backgroundColor;
      if (isHighlighted) {
        backgroundColor = isDark
            ? const Color(0xFF2A4A42)
            : const Color(0xFFB2DFDB);
      } else if (isRecitationError) {
        backgroundColor = isDark
            ? const Color(0xFF5C1B1B)
            : const Color(0xFFFFEBEE);
      } else if (isBookmarked) {
        backgroundColor = isDark
            ? const Color(0xFF1E3A35)
            : const Color(0xFFE8F5E9);
      }

      final Color effectiveColor = isBlurred ? Colors.transparent : textColor;
      final List<Shadow>? shadows = isBlurred
          ? [Shadow(color: textColor, blurRadius: 20.0, offset: Offset.zero)]
          : null;

      String verseText = '${aya.text} ';

      // Strip Bismillah if it's the first verse of a Surah that isn't Al-Fatiha
      if (aya.verseNumber == 1 && surah?.id != 1) {
        // EXACT string from the JSON assets (surah_3.json)
        // characters: Ba, Kasra, Sin, Sukun, Mim, Space, Allah...
        const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

        // Remove Bismillah and any leading whitespace
        if (verseText.startsWith(bismillahPrefix)) {
          verseText = verseText.substring(bismillahPrefix.length).trim();
        } else {
          // Fallback: Check for standard Bismillah without the specific diacritics of the local file
          // just in case some files differ (though unlikely if they are from same source).
          const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
          if (verseText.startsWith(bismillahSimple)) {
            verseText = verseText.substring(bismillahSimple.length).trim();
          }
        }
      }

      // Anchor span for reliable scroll-to-ayah in rich text mode
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            key: _richTextVerseKeys.putIfAbsent(
              aya.verseNumber,
              () => GlobalKey(debugLabel: 'verse_anchor_${aya.verseNumber}'),
            ),
            width: 0,
            height: 0,
          ),
        ),
      );
      // WidgetSpan contributes a placeholder character to text offsets.
      currentOffset += 1;

      // Record Range (Text)
      verseRanges.add(
        _VerseRange(
          start: currentOffset,
          end: currentOffset + verseText.length,
          verse: aya,
          isBadge: false,
          isBookmarked: isBookmarked,
          isError: isRecitationError,
        ),
      );

      spans.add(
        TextSpan(
          text: verseText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24, // Increased for better readability
            fontWeight: FontWeight
                .normal, // Regular weight preserves tashkil/ligatures better
            color: effectiveColor,
            backgroundColor: backgroundColor,
            shadows: shadows,
            height:
                2.2, // Increased line height to prevents clipping of high waqf marks
          ),
        ),
      );
      currentOffset += verseText.length;

      // Verse End Badge Span
      verseRanges.add(
        _VerseRange(
          start: currentOffset,
          end: currentOffset + 1,
          verse: aya,
          isBadge: true,
          isBookmarked: isBookmarked,
          isError: isRecitationError,
        ),
      );

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: badgeGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: badgeBorder, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                aya.verseNumber.toLocalizedNumber(context),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeText,
                ),
              ),
            ),
          ),
        ),
      );
      currentOffset += 1;
    }

    final textSpan = TextSpan(children: spans);
    _currentVerseRanges = verseRanges; // Update member for scrolling

    return LayoutBuilder(
      builder: (context, constraints) {
        return Semantics(
          label: 'lbl_quran_text'.tr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final range = _findRange(details.localPosition, verseRanges);
              if (range == null) return;

              if (_isHifzMode) {
                // Unblur (toggle reveal) only
                setState(() {
                  if (_revealedVerses.contains(range.verse.verseNumber)) {
                    _revealedVerses.remove(range.verse.verseNumber);
                  } else {
                    _revealedVerses.add(range.verse.verseNumber);
                  }
                });
              } else {
                // Standard mode: Open menu
                // Save interaction
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    range.verse.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _showVerseMenu(
                  context,
                  range.verse,
                  range.isBookmarked,
                  range.isError,
                );
              }
            },
            onLongPressStart: (details) {
              if (_isHifzMode) {
                // Hifz mode: Open menu on long press
                final range = _findRange(details.localPosition, verseRanges);
                if (range != null) {
                  _showVerseMenu(
                    context,
                    range.verse,
                    range.isBookmarked,
                    range.isError,
                  );
                }
              }
            },
            child: RichText(
              key: _richTextKey,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              text: textSpan,
            ),
          ),
        );
      },
    );
  }

  _VerseRange? _findRange(Offset localPosition, List<_VerseRange> ranges) {
    final RenderObject? renderObject = _richTextKey.currentContext
        ?.findRenderObject();
    if (renderObject is RenderParagraph) {
      final TextPosition position = renderObject.getPositionForOffset(
        localPosition,
      );
      final offset = position.offset;

      for (final range in ranges) {
        if (offset >= range.start && offset < range.end) {
          return range;
        }
      }
    }
    return null;
  }

  Widget _buildSingleLineContent(
    BuildContext context,
    List<Verse> chapters,
    BookmarkState bookmarkState,
    RecitationErrorState errorState,
    bool isDark,
  ) {
    final Color textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF004B40);
    final Color badgeBorder = isDark
        ? const Color(0xFF87D1A4)
        : const Color(0xFF006754);
    final Color badgeText = isDark
        ? const Color(0xFFFAF6EB)
        : const Color(0xFF004B40);
    final List<Color> badgeGradient = isDark
        ? [const Color(0xFF113C35), const Color(0xFF0B2D28)]
        : [const Color(0xFFFAF6EB), const Color(0xFFEDE6D6)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: chapters.map((aya) {
        bool isBookmarked = false;
        if (bookmarkState is BookmarkLoaded) {
          isBookmarked = bookmarkState.bookmarks.any(
            (b) =>
                b.surahId == (surah?.id ?? -1) &&
                b.verseNumber == aya.verseNumber,
          );
        }
        bool isRecitationError = false;
        if (errorState is RecitationErrorLoaded) {
          isRecitationError = errorState.errors.any(
            (m) =>
                m.surahId == (surah?.id ?? -1) && m.verseId == aya.verseNumber,
          );
        }

        bool isBlurred =
            _isHifzMode && !_revealedVerses.contains(aya.verseNumber);
        bool isHighlighted = _highlightedVerse == aya.verseNumber;

        Color? backgroundColor;
        if (isHighlighted) {
          backgroundColor = isDark
              ? const Color(0xFF2A4A42)
              : const Color(0xFFB2DFDB);
        } else if (isRecitationError) {
          backgroundColor = isDark
              ? const Color(0xFF5C1B1B)
              : const Color(0xFFFFEBEE);
        } else if (isBookmarked) {
          backgroundColor = isDark
              ? const Color(0xFF1E3A35)
              : const Color(0xFFE8F5E9);
        }

        String verseText = aya.text;
        if (aya.verseNumber == 1 && surah?.id != 1) {
          const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
          if (verseText.startsWith(bismillahPrefix)) {
            verseText = verseText.substring(bismillahPrefix.length).trim();
          } else {
            const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
            if (verseText.startsWith(bismillahSimple)) {
              verseText = verseText.substring(bismillahSimple.length).trim();
            }
          }
        }

        return Semantics(
          button: true,
          label: '${'lbl_ayah'.tr} ${aya.verseNumber}',
          child: GestureDetector(
            onTap: () {
              if (_isHifzMode) {
                setState(() {
                  if (_revealedVerses.contains(aya.verseNumber)) {
                    _revealedVerses.remove(aya.verseNumber);
                  } else {
                    _revealedVerses.add(aya.verseNumber);
                  }
                });
              } else {
                // Save interaction
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    aya.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _showVerseMenu(context, aya, isBookmarked, isRecitationError);
              }
            },
            onLongPress: () {
              if (_isHifzMode) {
                _showVerseMenu(context, aya, isBookmarked, isRecitationError);
              }
            },

            child: Container(
              key: _verseKeys.putIfAbsent(
                aya.verseNumber,
                () => GlobalKey(debugLabel: 'verse_${aya.verseNumber}'),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: (isBookmarked || isRecitationError || isHighlighted)
                    ? Border.all(
                        color: isHighlighted
                            ? Colors.teal.withValues(alpha: 0.5)
                            : isRecitationError
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.teal.withValues(alpha: 0.3),
                        width: isHighlighted ? 2 : 1,
                      )
                    : null,
              ),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    verseText,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24, // Increased
                      fontWeight: FontWeight.normal, // Regular weight
                      color: isBlurred ? Colors.transparent : textColor,
                      height: 2.2, // Taller line height
                      shadows: isBlurred
                          ? [
                              Shadow(
                                color: textColor,
                                blurRadius: 20.0,
                                offset: Offset.zero,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: badgeGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: badgeBorder, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        aya.verseNumber.toLocalizedNumber(context),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VerseRange {
  final int start;
  final int end;
  final Verse verse;
  final bool isBadge;
  final bool isBookmarked;
  final bool isError;

  _VerseRange({
    required this.start,
    required this.end,
    required this.verse,
    this.isBadge = false,
    this.isBookmarked = false,
    this.isError = false,
  });
}

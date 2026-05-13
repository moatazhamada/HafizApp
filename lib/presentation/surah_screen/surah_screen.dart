import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hafiz_app/presentation/surah_screen/voice_verification_service.dart';

import 'widgets/auto_scroll_speed_sheet.dart';
import 'widgets/bismillah_widget.dart';
import 'widgets/completion_dialog.dart';
import 'widgets/surah_navigation_bar.dart';
import 'widgets/tafsir_sheet.dart';
import 'widgets/verse_menu_sheet.dart';
import 'widgets/verse_range.dart';
import 'widgets/voice_verification_dialog.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/app_export.dart';
import '../../core/utils/rtl_utils.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/qiraat/qiraat_service.dart';
import '../../core/qrc/adaptive_qrc.dart';
import '../../core/quran_index/quran_surah.dart';
import '../../core/services/reading_session_tracker.dart';
import '../../domain/entities/reading_session.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import '../../core/quran_index/quran_verse_utils.dart';
import '../../core/quran_index/sajdah_index.dart';
import '../../domain/entities/verse.dart';
import '../../injection_container.dart';
import 'bloc/surah_bloc.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_event.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_state.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_event.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import '../../domain/repository/khatmah_repository.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/surah_name_formatter.dart';
import '../../core/theme/app_colors.dart';
import 'package:hafiz_app/data/datasource/translation/qf_translation_remote_data_source.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';

part 'widgets/_surah_app_bar.dart';
part 'widgets/_verse_list_view.dart';
part 'widgets/_hifz_mode_overlay.dart';
part 'widgets/_audio_control_bar.dart';
part 'widgets/_auto_scroll_controls.dart';
part 'widgets/_completion_celebration.dart';
part 'widgets/_voice_verification_panel.dart';

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
  int? _selectedVerse;
  int? _highlightedVerse;

  // Translation State
  bool _showTranslation = false;
  Map<int, String> _translations = {};
  bool _translationsLoading = false;

  // Scroll Keys
  final Map<int, GlobalKey> _verseKeys = {};
  final Map<int, GlobalKey> _richTextVerseKeys = {};
  List<VerseRange> _currentVerseRanges = [];

  // Key for accurate hit testing on RichText with WidgetSpans
  final GlobalKey _richTextKey = GlobalKey();

  // Voice Verification
  final GlobalKey<_VoiceVerificationPanelState> _voicePanelKey =
      GlobalKey<_VoiceVerificationPanelState>();
  final GlobalKey<_CompletionCelebrationState> _completionKey =
      GlobalKey<_CompletionCelebrationState>();

  // Auto-scroll
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 0.5;

  // Listening Mode (audio-coupled auto-scroll)
  bool _isListeningMode = false;
  StreamSubscription<int>? _listeningSubscription;
  List<Verse> _chapters = []; // Cached for listening mode toggle

  // Reading Session Tracking
  final ReadingSessionTracker _sessionTracker = ReadingSessionTracker();

  @override
  void initState() {
    super.initState();
    _showTranslation = PrefUtils().getShowTranslation();
    LocaleController.notifier.addListener(_onLocaleChanged);
    if (PrefUtils().isKeepScreenOn()) {
      WakelockPlus.enable();
    }
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
          _selectedVerse = vIndex + 1;
          _highlightedVerse = vIndex + 1;
        } else {
          final off = args['offset'];
          if (off is num) initialOffset = off.toDouble();
        }
      }

      if (surah != null) {
        surahBloc.add(LoadSurahEvent(surahId: surah?.id.toString() ?? ''));
        final isArabic = LocaleController.notifier.value.languageCode == 'ar';
        if (_showTranslation && !isArabic) _loadTranslations();
        _sessionTracker.startSession(
          surahId: surah!.id,
          startVerse: _selectedVerse ?? 1,
        );
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
          final visibleVerse = _findVisibleVerseNumber();
          if (visibleVerse != null) {
            _sessionTracker.updateProgress(visibleVerse);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    final session = _sessionTracker.endSession();
    if (session != null) {
      _postReadingSession(session);
    }
    LocaleController.notifier.removeListener(_onLocaleChanged);
    _offsetSaveDebounce?.cancel();
    _autoScrollTimer?.cancel();
    _listeningSubscription?.cancel();
    if (_isListeningMode) AudioPlayerHandler().stop();

    _scrollControllerForInit?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _clearHighlight() {
    setState(() => _highlightedVerse = null);
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    if (_isAutoScrolling) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _toggleListeningMode() {
    if (_isListeningMode) {
      _stopListeningMode();
    } else {
      if (_chapters.isEmpty) return;
      _startListeningMode(_chapters);
    }
  }

  void _startListeningMode(List<Verse> chapters) {
    if (surah == null) return;
    final handler = AudioPlayerHandler();
    setState(() => _isListeningMode = true);

    _listeningSubscription = handler.currentVerseStream.listen((verseIndex) {
      if (!_isListeningMode || !mounted) return;
      setState(() {
        _highlightedVerse = verseIndex >= 0 ? verseIndex + 1 : null;
      });
      if (verseIndex >= 0) {
        _scrollToVerse(verseIndex + 1, chapters);
        PrefUtils().setLastAudioVerse(surah!.id, verseIndex);
      }
    });

    final reciterId = PrefUtils().getReciterId();
    final reciterCdnIds = {
      7: 'ar.alafasy',
      9: 'ar.abdurrahmaansudais',
      1: 'ar.abdulbasitmurattal',
      5: 'ar.husary',
      17: 'ar.minshawi',
    };
    final cdnId = reciterCdnIds[reciterId] ?? 'ar.alafasy';
    final totalVerses = chapters.length;
    final urls = List.generate(totalVerses, (i) {
      final absolute = absoluteVerseNumber(surah!.id, i + 1);
      return 'https://cdn.islamic.network/quran/audio/128/$cdnId/$absolute.mp3';
    });
    handler.playSurah(surahId: surah!.id, verseAudioUrls: urls);
  }

  void _stopListeningMode() {
    _listeningSubscription?.cancel();
    _listeningSubscription = null;
    AudioPlayerHandler().stop();
    setState(() {
      _isListeningMode = false;
      _highlightedVerse = null;
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_scrollController.hasClients && _isAutoScrolling) {
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (current < max) {
          _scrollController.jumpTo(current + _autoScrollSpeed);
        } else {
          _autoScrollTimer?.cancel();
          setState(() => _isAutoScrolling = false);
        }
      }
    });
  }

  void _showAutoScrollSpeedDialog() {
    showAutoScrollSpeedPicker(
      context,
      currentSpeed: _autoScrollSpeed,
      onSpeedSelected: (speed) => setState(() => _autoScrollSpeed = speed),
    );
  }

  void _navigateToSurah(int surahId) {
    if (surahId < 1 || surahId > 114) return;
    final targetSurah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == surahId,
    );
    NavigatorService.popAndPushNamed(
      AppRoutes.surahPage,
      arguments: {'surah': targetSurah},
    );
  }

  Future<void> _loadTranslations() async {
    if (_translations.isNotEmpty || _translationsLoading) return;
    if (surah == null) return;
    setState(() => _translationsLoading = true);
    try {
      final ds = sl<QfTranslationRemoteDataSource>();
      _translations = await ds.getTranslationsByChapter(surah!.id);
    } catch (e) {
      Logger.warning(
        'Failed to load translations for surah ${surah!.id}: $e',
        feature: 'Translation',
      );
    }
    if (mounted) setState(() => _translationsLoading = false);
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    final isArabic = LocaleController.notifier.value.languageCode == 'ar';
    setState(() {
      _translations = {};
      _translationsLoading = false;
      if (isArabic) {
        _showTranslation = false;
        PrefUtils().setShowTranslation(false);
      }
    });
    try {
      sl<QfTranslationRemoteDataSource>().clearCache();
    } catch (e) {
      Logger.warning('Translation cache clear failed: $e', feature: 'Translation');
    }
    if (!isArabic && PrefUtils().getShowTranslation()) {
      _showTranslation = true;
      _loadTranslations();
    }
  }

  Future<void> _postReadingSession(ReadingSession session) async {
    try {
      final isAuthenticated = await sl<QfAuthRemoteDataSource>().isAuthenticated();
      if (!isAuthenticated) return;
      final dataSource = sl<QfGoalsRemoteDataSource>();
      await dataSource.postReadingSession(
        chapterNumber: session.surahId,
        verseNumber: session.startVerse,
        startVerse: session.startVerse,
        endVerse: session.endVerse,
        duration: session.durationSeconds,
        readAt: session.readAt,
      );
      Logger.info(
        'Reading session posted to QF: ${session.surahId}:${session.startVerse}-${session.endVerse}',
        feature: 'ReadingSessions',
      );
    } catch (e) {
      Logger.warning(
        'Failed to post reading session: $e',
        feature: 'ReadingSessions',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: colors.scaffoldBackground,
        bottomNavigationBar: surah != null
            ? SurahNavigationBar(surah: surah!, onNavigate: _navigateToSurah)
            : null,
        body: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            _saveReadingProgress();
            final session = _sessionTracker.endSession();
            if (session != null) {
              _postReadingSession(session);
            }
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
                      SnackBarHelper.show(
                        context,
                        message: state.feedbackMessage!.tr,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
                BlocListener<RecitationErrorBloc, RecitationErrorState>(
                  listener: (context, state) {
                    if (state is RecitationErrorLoaded &&
                        state.feedbackMessage != null) {
                      SnackBarHelper.show(
                        context,
                        message: state.feedbackMessage!.tr,
                        type: SnackBarType.error,
                        duration: const Duration(seconds: 2),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              state.errorMessage.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.read<SurahBloc>().add(
                              LoadSurahEvent(surahId: '${surah!.id}'),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: Text('lbl_retry'.tr),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final chapters = (state as SuccessSurahState).chapters;
                    _chapters = chapters;
                    if (_selectedVerse != null && chapters.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedVerse != null) {
                          _scrollToVerseWithRetry(_selectedVerse!, chapters);
                          _selectedVerse = null;
                        }
                      });
                    }

                    return BlocBuilder<BookmarkBloc, BookmarkState>(
                      buildWhen: (previous, current) {
                        final prevBookmarks = previous is BookmarkLoaded
                            ? previous.bookmarks
                            : null;
                        final currBookmarks = current is BookmarkLoaded
                            ? current.bookmarks
                            : null;
                        return prevBookmarks != currBookmarks;
                      },
                      builder: (context, bookmarkState) {
                        return BlocBuilder<
                          RecitationErrorBloc,
                          RecitationErrorState
                        >(
                          buildWhen: (previous, current) {
                            final prevErrors = previous is RecitationErrorLoaded
                                ? previous.errors
                                : null;
                            final currErrors = current is RecitationErrorLoaded
                                ? current.errors
                                : null;
                            return prevErrors != currErrors;
                          },
                          builder: (context, errorState) {
                            return CustomScrollView(
                              controller: _scrollController,
                              slivers: [
                                _SurahAppBar(
                                  isDark: isDark,
                                  surah: surah,
                                  isAutoScrolling: _isAutoScrolling,
                                  autoScrollSpeed: _autoScrollSpeed,
                                  isListeningMode: _isListeningMode,
                                  isHifzMode: _isHifzMode,
                                  showTranslation: _showTranslation,
                                  highlightedVerse: _highlightedVerse,
                                  onToggleAutoScroll: _toggleAutoScroll,
                                  onShowAutoScrollSpeedDialog:
                                      _showAutoScrollSpeedDialog,
                                  onToggleListeningMode: _toggleListeningMode,
                                  onToggleHifzMode: () {
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _isHifzMode = !_isHifzMode;
                                      _revealedVerses.clear();
                                    });
                                    SemanticsService.sendAnnouncement(
                                      View.of(context),
                                      _isHifzMode
                                          ? 'lbl_hifz_mode_on'.tr
                                          : 'lbl_hifz_mode_off'.tr,
                                      TextDirection.ltr,
                                    );
                                  },
                                  onToggleBookmark: () {
                                    HapticFeedback.lightImpact();
                                    final blocState =
                                        context.read<BookmarkBloc>().state;
                                    final isSurahBookmarked =
                                        blocState is BookmarkLoaded &&
                                        blocState.bookmarks.any(
                                          (b) =>
                                              b.surahId == surah?.id &&
                                              b.verseNumber == 1,
                                        );
                                    if (isSurahBookmarked) {
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
                                    try {
                                      context
                                          .read<CloudSyncBloc>()
                                          .add(SyncWithQfEvent());
                                    } catch (e) {
                                      Logger.warning(
                                        'Bookmark sync trigger failed: $e',
                                        feature: 'Bookmarks',
                                      );
                                    }
                                  },
                                  onToggleTranslation: () {
                                    setState(() {
                                      _showTranslation = !_showTranslation;
                                      PrefUtils().setShowTranslation(
                                        _showTranslation,
                                      );
                                    });
                                    if (_showTranslation) _loadTranslations();
                                  },
                                  onNavigateToHelp: () => NavigatorService
                                      .pushNamed(AppRoutes.helpScreen),
                                  onNavigateToAudioPlayer: (startVerse) {
                                    if (surah == null) return;
                                    final isArabic = Localizations.localeOf(
                                      context,
                                    ).languageCode == 'ar';
                                    NavigatorService.pushNamed(
                                      AppRoutes.audioPlayerScreen,
                                      arguments: {
                                        'surahId': surah!.id,
                                        'surahName': isArabic
                                            ? surah!.nameArabic
                                            : surah!.nameEnglish,
                                        'startVerse': ?startVerse,
                                      },
                                    );
                                  },
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 20.v,
                                  ),
                                  sliver: _VerseListView(
                                    chapters: chapters,
                                    bookmarkState: bookmarkState,
                                    errorState: errorState,
                                    isDark: isDark,
                                    surah: surah,
                                    isHifzMode: _isHifzMode,
                                    revealedVerses: _revealedVerses,
                                    highlightedVerse: _highlightedVerse,
                                    showTranslation: _showTranslation,
                                    translations: _translations,
                                    verseKeys: _verseKeys,
                                    richTextVerseKeys: _richTextVerseKeys,
                                    richTextKey: _richTextKey,
                                    currentVerseRanges: _currentVerseRanges,
                                    onUpdateVerseRanges:
                                        (ranges) =>
                                            _currentVerseRanges = ranges,
                                    onToggleHifzReveal: (verseNumber) {
                                      setState(() {
                                        if (_revealedVerses
                                            .contains(verseNumber)) {
                                          _revealedVerses
                                              .remove(verseNumber);
                                        } else {
                                          _revealedVerses.add(verseNumber);
                                        }
                                      });
                                    },
                                    onVerifyRecitation: (aya) =>
                                        _voicePanelKey.currentState
                                            ?.show(aya),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: _VoiceVerificationPanel(
                                    key: _voicePanelKey,
                                    surah: surah,
                                    surahBloc: surahBloc,
                                    completionKey: _completionKey,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: _CompletionCelebration(
                                    key: _completionKey,
                                    surah: surah,
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
}

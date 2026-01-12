import "package:flutter/material.dart";

import "../../core/app_export.dart";
import "../../core/quran_index/quran_surah.dart";
import "../../core/scroll/scroll_position_cubit.dart";
import "../../data/model/surah_response.dart";
import "../../injection_container.dart";
import "bloc/surah_bloc.dart";
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen>
    with AutomaticKeepAliveClientMixin {
  final surahBloc = sl<SurahBloc>();
  Surah? surah;
  double? initialOffset;
  int? initialVerseIndex;
  final scrollCubit = sl<ScrollPositionCubit>();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _scrolledOnce = false;
  bool _hasSavedResume = false;
  bool resumeRequested = false;

  // Hifz Mode State
  bool _isHifzMode = false;
  final Set<int> _revealedVerses = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Retrieve the data from the arguments (supports Surah or {surah, offset})
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Surah) {
        surah = args;
      } else if (args is Map) {
        surah = args['surah'] as Surah?;
        final off = args['offset'];
        if (off is num) initialOffset = off.toDouble();
        final vi = args['verseIndex'];
        if (vi is int) initialVerseIndex = vi;
        final r = args['resume'];
        if (r is bool) resumeRequested = r;
      }

      if (surah != null) {
        surahBloc.add(LoadSurahEvent(surahId: surah?.id.toString() ?? ""));
        if (mounted) setState(() {});
        // Track first visible verse index and persist
        _itemPositionsListener.itemPositions.addListener(() {
          final positions = _itemPositionsListener.itemPositions.value;
          if (positions.isEmpty) return;

          final versePositions = positions.toList();
          if (versePositions.isEmpty) return;
          final min = versePositions
              .reduce((a, b) => a.index < b.index ? a : b)
              .index;
          // Index 0 in list = Verse 1. Stored index 1 = Verse 1.
          // Wait, PrefUtils usually stores verseId or index? Assuming 1-based verseId usually good for readability but let's see.
          // Before: index 1 was Verse 1. (min - 1) -> 0.
          // Now: index 0 is Verse 1. min -> 0.
          // So 'verseIndex' represents 0-based verse index.

          final verseIndex = min.clamp(0, 10000);
          PrefUtils().setSurahVerseIndex(surah!.id, verseIndex);

          // Show resume FAB if we scrolled past first few verses?
          // Or just if we have resumed?
          // Let's say if index > 0 (scrolled down).
          final show = verseIndex > 0;
          if (show != _hasSavedResume && mounted) {
            setState(() => _hasSavedResume = show);
          }
        });
        // Check saved resume index to display FAB
        final savedIndex =
            initialVerseIndex ?? PrefUtils().getSurahVerseIndex(surah!.id);
        if (savedIndex != null && savedIndex > 0) {
          setState(() => _hasSavedResume = true);
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // No explicit controller to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          // Nothing to do; verse index already persisted via listener
        },
        child: Scaffold(
          backgroundColor: Color(
            PrefUtils().getIsDarkMode() == true ? 0xFF000000 : 0xFFFFFFFF,
          ),
          body: MultiBlocProvider(
            providers: [
              BlocProvider<SurahBloc>(create: (context) => surahBloc),
              BlocProvider<BookmarkBloc>(
                create: (context) =>
                    sl<BookmarkBloc>()
                      ..add(LoadBookmarksEvent()), // Load to check status
              ),
              BlocProvider<RecitationErrorBloc>(
                create: (context) =>
                    sl<RecitationErrorBloc>()..add(LoadRecitationErrorsEvent()),
              ),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<BookmarkBloc, BookmarkState>(
                  listener: (context, state) {
                    if (state is BookmarkLoaded &&
                        state.feedbackMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.feedbackMessage!),
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
                          content: Text(state.feedbackMessage!),
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
                    return Center(child: Text(state.errorMessage));
                  } else {
                    final chapters = (state as SuccessSurahState).chapters;
                    // Scroll to saved verse index once (after list is attached)
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (_scrolledOnce || surah == null || !resumeRequested) {
                        return;
                      }
                      if (chapters.isEmpty) return;

                      // Ensure list has attached at least one position
                      final hasAttachment =
                          _itemPositionsListener.itemPositions.value.isNotEmpty;
                      if (!hasAttachment) {
                        // Retry next frame
                        WidgetsBinding.instance.addPostFrameCallback((_) {});
                        return;
                      }

                      final savedIndex =
                          initialVerseIndex ??
                          PrefUtils().getSurahVerseIndex(surah!.id);
                      if (savedIndex == null || savedIndex < 0) return;

                      final maxVerse = chapters.length - 1;
                      final clampedVerse = savedIndex > maxVerse
                          ? maxVerse
                          : savedIndex;
                      final target = clampedVerse + 1; // header at 0
                      try {
                        await _itemScrollController.scrollTo(
                          index: target,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          alignment: 0.0,
                        );
                        _scrolledOnce = true;
                      } catch (_) {
                        // Retry on next frame if the list wasn't ready yet
                        WidgetsBinding.instance.addPostFrameCallback((_) {});
                      }
                    });
                    return BlocBuilder<BookmarkBloc, BookmarkState>(
                      builder: (context, bookmarkState) {
                        return BlocBuilder<
                          RecitationErrorBloc,
                          RecitationErrorState
                        >(
                          builder: (context, errorState) {
                            return Stack(
                              children: [
                                ScrollablePositionedList.builder(
                                  padding: EdgeInsets.only(
                                    top: 180.v,
                                    bottom: 20.v,
                                  ),
                                  itemScrollController: _itemScrollController,
                                  itemPositionsListener: _itemPositionsListener,
                                  itemCount: chapters.length,
                                  itemBuilder: (context, index) {
                                    final aya = chapters[index];
                                    // Check bookmarks
                                    bool isBookmarked = false;
                                    if (bookmarkState is BookmarkLoaded) {
                                      isBookmarked = bookmarkState.bookmarks
                                          .any(
                                            (b) =>
                                                b.surahId ==
                                                    (surah?.id ?? -1) &&
                                                b.verseId == aya.verse,
                                          );
                                    }
                                    // Check errors
                                    bool isRecitationError = false;
                                    if (errorState is RecitationErrorLoaded) {
                                      isRecitationError = errorState.errors.any(
                                        (m) =>
                                            m.surahId == (surah?.id ?? -1) &&
                                            m.verseId == aya.verse,
                                      );
                                    }

                                    // Check Hifz Mode blur
                                    bool isBlurred =
                                        _isHifzMode &&
                                        !_revealedVerses.contains(aya.verse);

                                    return AyaListItem(
                                      aya: aya,
                                      isBookmarked: isBookmarked,
                                      isRecitationError:
                                          isRecitationError, // Pass error status
                                      isBlurred: isBlurred,
                                      onTap: _isHifzMode
                                          ? () {
                                              setState(() {
                                                if (_revealedVerses.contains(
                                                  aya.verse,
                                                )) {
                                                  _revealedVerses.remove(
                                                    aya.verse,
                                                  );
                                                } else {
                                                  _revealedVerses.add(
                                                    aya.verse,
                                                  );
                                                }
                                              });
                                            }
                                          : null,
                                      onLongPress: () {
                                        if (surah == null) return;
                                        showModalBottomSheet(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                          ),
                                          builder: (context) => SafeArea(
                                            child: Wrap(
                                              children: [
                                                ListTile(
                                                  leading: Icon(
                                                    isBookmarked
                                                        ? Icons.bookmark_remove
                                                        : Icons.bookmark_add,
                                                    color: Colors.teal,
                                                  ),
                                                  title: Text(
                                                    isBookmarked
                                                        ? 'Remove Bookmark'
                                                        : 'Add Bookmark',
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    if (isBookmarked) {
                                                      context
                                                          .read<BookmarkBloc>()
                                                          .add(
                                                            RemoveBookmarkEvent(
                                                              surah!.id,
                                                              aya.verse,
                                                            ),
                                                          );
                                                    } else {
                                                      context
                                                          .read<BookmarkBloc>()
                                                          .add(
                                                            AddBookmarkEvent(
                                                              BookmarkModel(
                                                                surahId:
                                                                    surah!.id,
                                                                surahName: surah!
                                                                    .nameEnglish,
                                                                verseId:
                                                                    aya.verse,
                                                                createdAt:
                                                                    DateTime.now(),
                                                              ),
                                                            ),
                                                          );
                                                    }
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(
                                                    isRecitationError
                                                        ? Icons.playlist_remove
                                                        : Icons.error_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  title: Text(
                                                    isRecitationError
                                                        ? 'Remove as Error'
                                                        : 'Mark as Error',
                                                    style: const TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    if (isRecitationError) {
                                                      context
                                                          .read<
                                                            RecitationErrorBloc
                                                          >()
                                                          .add(
                                                            RemoveRecitationErrorEvent(
                                                              surah!.id,
                                                              aya.verse,
                                                            ),
                                                          );
                                                    } else {
                                                      context
                                                          .read<
                                                            RecitationErrorBloc
                                                          >()
                                                          .add(
                                                            AddRecitationErrorEvent(
                                                              RecitationErrorModel(
                                                                surahId:
                                                                    surah!.id,
                                                                surahName: surah!
                                                                    .nameEnglish,
                                                                verseId:
                                                                    aya.verse,
                                                                createdAt:
                                                                    DateTime.now(),
                                                              ),
                                                            ),
                                                          );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildAppBar(),
                                ),
                                // One-time auto scroll overlay logic (preserved)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Builder(
                                      builder: (context) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) async {
                                              if (_scrolledOnce ||
                                                  surah == null ||
                                                  !resumeRequested) {
                                                return;
                                              }
                                              if (chapters.isEmpty) return;
                                              final attached =
                                                  _itemPositionsListener
                                                      .itemPositions
                                                      .value
                                                      .isNotEmpty;
                                              if (!attached) return;
                                              final savedIndex =
                                                  initialVerseIndex ??
                                                  PrefUtils()
                                                      .getSurahVerseIndex(
                                                        surah!.id,
                                                      );
                                              if (savedIndex == null ||
                                                  savedIndex <= 0) {
                                                _scrolledOnce = true;
                                                return;
                                              }
                                              final maxVerse =
                                                  chapters.length - 1;
                                              final clampedVerse =
                                                  savedIndex > maxVerse
                                                  ? maxVerse
                                                  : savedIndex;
                                              final target = clampedVerse;
                                              try {
                                                await _itemScrollController
                                                    .scrollTo(
                                                      index: target,
                                                      duration: const Duration(
                                                        milliseconds: 350,
                                                      ),
                                                      curve:
                                                          Curves.easeOutCubic,
                                                      alignment: 0.0,
                                                    );
                                              } catch (_) {}
                                              _scrolledOnce = true;
                                            });
                                        return const SizedBox.shrink();
                                      },
                                    ),
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

  Widget _buildAppBar() {
    return Stack(
      children: [
        Positioned(
          right: -55,
          bottom: -10,
          child: CustomImageView(
            fit: BoxFit.cover,
            imagePath: ImageConstant.imgQuranOnboarding,
            height: 150.v,
            width: 150.h,
          ),
        ),
        Container(
          height: 180.v,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006754), Color(0xDB87D1A4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    NavigatorService.goBack();
                  },
                  child: const Icon(
                    Icons.arrow_back_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'surah-title-${surah?.id ?? 'unknown'}',
                        child: Text(
                          surah?.nameArabic ?? "",
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: "Amiri",
                          ),
                        ),
                      ),
                      surah?.id == 9
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 1.adaptSize,
                                width: 144.h,
                                color: const Color(0xFFD9D8D8),
                              ),
                            ),
                      surah?.id == 9
                          ? const SizedBox.shrink()
                          : CustomImageView(
                              imagePath: ImageConstant.imgBismillah,
                            ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isHifzMode = !_isHifzMode;
                      _revealedVerses.clear();
                    });
                  },
                  child: Icon(
                    _isHifzMode ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16.h),
                BlocBuilder<BookmarkBloc, BookmarkState>(
                  builder: (context, state) {
                    bool isBookmarked = false;
                    if (state is BookmarkLoaded) {
                      isBookmarked = state.bookmarks.any(
                        (element) => element.surahId == (surah?.id ?? -1),
                      );
                    }
                    return InkWell(
                      onTap: () {
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
                                verseId: 1,
                                createdAt: DateTime.now(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AyaListItem extends StatelessWidget {
  final Chapter aya;
  final bool isBookmarked;
  final bool isRecitationError;
  final bool isBlurred;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const AyaListItem({
    super.key,
    required this.aya,
    this.isBookmarked = false,
    this.isRecitationError = false,
    this.isBlurred = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = PrefUtils().getIsDarkMode();
    // Keep a single source of truth for font size
    const double ayahFontSize = 20;
    const double badgeGap = 12; // visual space between last char and badge
    final double badgeDiameter = ayahFontSize * 1.25; // scale badge with text

    final Color textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF004B40);
    final List<Color> badgeGradient = isDark
        ? [const Color(0xFF113C35), const Color(0xFF0B2D28)]
        : [const Color(0xFFFAF6EB), const Color(0xFFEDE6D6)];
    final Color badgeBorder = isDark
        ? const Color(0xFF87D1A4)
        : const Color(0xFF006754);
    final Color badgeText = isDark
        ? const Color(0xFFFAF6EB)
        : const Color(0xFF004B40);

    // Blur effect Logic:
    // If IS BLURRED: Make text transparent and apply a heavy shadow to simulate blur.
    // If REVEALED (not blurred): Normal text.
    final Color effectiveTextColor = isBlurred ? Colors.transparent : textColor;
    final List<Shadow>? textShadows = isBlurred
        ? [
            Shadow(
              color: textColor.withValues(alpha: 0.5),
              blurRadius: 8.0,
              offset: Offset.zero,
            ),
          ]
        : null;

    Color? backgroundColor;
    if (isRecitationError) {
      backgroundColor = isDark
          ? const Color(0xFF5C1B1B)
          : const Color(0xFFFFEBEE); // Red tint
    } else if (isBookmarked) {
      backgroundColor = isDark
          ? const Color(0xFF1E3A35)
          : const Color(0xFFE8F5E9); // Green tint
    }

    return InkWell(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 16.0,
        ),
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              TextSpan(
                text: aya.text,
                style: TextStyle(
                  fontSize: ayahFontSize,
                  fontWeight: FontWeight.w700,
                  color: effectiveTextColor,
                  shadows: textShadows,
                  fontFamily: "Amiri",
                ),
              ),
              // Add a textual space for better semantics/copying in addition to visual gap
              const TextSpan(text: ' '),
              const WidgetSpan(child: SizedBox(width: badgeGap)),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  width: badgeDiameter,
                  height: badgeDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: badgeGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: badgeBorder, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${aya.verse}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ayahFontSize * 0.7,
                      fontWeight: FontWeight.w700,
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
  }
}

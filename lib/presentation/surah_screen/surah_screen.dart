import "package:flutter/material.dart";

import "../../core/app_export.dart";
import "../../core/quran_index/quran_surah.dart";

import "../../data/model/surah_response.dart";
import "../../injection_container.dart";
import "bloc/surah_bloc.dart";
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen>
    with AutomaticKeepAliveClientMixin {
  final surahBloc = sl<SurahBloc>();
  Surah? surah;

  // Scroll management
  final ScrollController _scrollController = ScrollController();
  double? initialOffset;

  // Hifz Mode State
  bool _isHifzMode = false;
  final Set<int> _revealedVerses = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Surah) {
        surah = args;
      } else if (args is Map) {
        surah = args['surah'] as Surah?;
        final off = args['offset'];
        if (off is num) initialOffset = off.toDouble();
      }

      if (surah != null) {
        surahBloc.add(LoadSurahEvent(surahId: surah?.id.toString() ?? ""));
        if (mounted) setState(() {});

        // Restore saved offset if available and no specific offset passed
        if (initialOffset == null) {
          // In a real app, we would load the pixel offset from Prefs or database
          // For now, we will just default to 0 or use the rudimentary index-based logic if we maintained it,
          // but since we switched to text flow, index-based scrolling is inaccurate.
          // We'll leave it at 0 for now as 'continuous flow' implies reading mode.
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = PrefUtils().getIsDarkMode();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(isDark == true ? 0xFF000000 : 0xFFFFFFFF),
        body: MultiBlocProvider(
          providers: [
            BlocProvider<SurahBloc>(create: (context) => surahBloc),
            BlocProvider<BookmarkBloc>(
              create: (context) =>
                  sl<BookmarkBloc>()..add(LoadBookmarksEvent()),
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
                  return BlocBuilder<BookmarkBloc, BookmarkState>(
                    builder: (context, bookmarkState) {
                      return BlocBuilder<
                        RecitationErrorBloc,
                        RecitationErrorState
                      >(
                        builder: (context, errorState) {
                          return Stack(
                            children: [
                              SingleChildScrollView(
                                controller: _scrollController,
                                padding: EdgeInsets.only(
                                  top: 180.v,
                                  bottom: 20.v,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: _buildSurahText(
                                  context,
                                  chapters,
                                  bookmarkState,
                                  errorState,
                                  isDark,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: _buildAppBar(),
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
    );
  }

  Widget _buildSurahText(
    BuildContext context,
    List<Chapter> chapters,
    BookmarkState bookmarkState,
    RecitationErrorState errorState,
    bool isDark,
  ) {
    const double fontSize = 22;
    // Theme colors
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

    for (var aya in chapters) {
      // Determine state
      bool isBookmarked = false;
      if (bookmarkState is BookmarkLoaded) {
        isBookmarked = bookmarkState.bookmarks.any(
          (b) => b.surahId == (surah?.id ?? -1) && b.verseId == aya.verse,
        );
      }
      bool isRecitationError = false;
      if (errorState is RecitationErrorLoaded) {
        isRecitationError = errorState.errors.any(
          (m) => m.surahId == (surah?.id ?? -1) && m.verseId == aya.verse,
        );
      }

      // Hifz Logic
      bool isBlurred = _isHifzMode && !_revealedVerses.contains(aya.verse);

      // Styling
      Color? backgroundColor;
      if (isRecitationError) {
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
          ? [
              Shadow(
                color: textColor, // Full opacity shadow
                blurRadius: 20.0,
                offset: Offset.zero,
              ),
            ]
          : null;

      final String verseText = "${aya.text} ";

      // Record Range (Text)
      // TextSpan adds `verseText.length` characters
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
            fontFamily: "Amiri",
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: effectiveColor,
            backgroundColor: backgroundColor,
            shadows: shadows,
          ),
        ),
      );
      currentOffset += verseText.length;

      // Verse End Badge Span
      // WidgetSpan counts as 1 character (placeholder 0xFFFC)
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
              width: 30, // fixed size badge
              height: 30,
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
                '${aya.verse}',
                style: TextStyle(
                  fontFamily: "Amiri",
                  fontSize: 12,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            _handleTap(
              context,
              details.localPosition,
              constraints.maxWidth,
              textSpan,
              verseRanges,
            );
          },
          onLongPressStart: (details) {
            _handleLongPress(
              context,
              details.localPosition,
              constraints.maxWidth,
              textSpan,
              verseRanges,
            );
          },
          child: RichText(
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            text: textSpan,
          ),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    Offset localPosition,
    double maxWidth,
    TextSpan textSpan,
    List<_VerseRange> ranges,
  ) {
    final range = _findRange(localPosition, maxWidth, textSpan, ranges);
    if (range != null) {
      if (range.isBadge) {
        // Tap on Badge -> Menu
        _showVerseMenu(context, range.verse, range.isBookmarked, range.isError);
      } else {
        // Tap on Text -> Toggle Blur (Hifz)
        if (_isHifzMode) {
          setState(() {
            if (_revealedVerses.contains(range.verse.verse)) {
              _revealedVerses.remove(range.verse.verse);
            } else {
              _revealedVerses.add(range.verse.verse);
            }
          });
        }
      }
    }
  }

  void _handleLongPress(
    BuildContext context,
    Offset localPosition,
    double maxWidth,
    TextSpan textSpan,
    List<_VerseRange> ranges,
  ) {
    final range = _findRange(localPosition, maxWidth, textSpan, ranges);
    if (range != null) {
      // Long Press anywhere -> Menu
      _showVerseMenu(context, range.verse, range.isBookmarked, range.isError);
    }
  }

  _VerseRange? _findRange(
    Offset localPosition,
    double maxWidth,
    TextSpan textSpan,
    List<_VerseRange> ranges,
  ) {
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      textScaler: MediaQuery.of(context).textScaler,
    );
    textPainter.layout(maxWidth: maxWidth);

    // Get text position from tap
    final position = textPainter.getPositionForOffset(localPosition);
    final offset = position.offset;

    // Find corresponding range
    for (final range in ranges) {
      if (offset >= range.start && offset < range.end) {
        return range;
      }
    }
    return null;
  }

  void _showVerseMenu(
    BuildContext context,
    Chapter aya,
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
            ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                color: Colors.teal,
              ),
              title: Text(isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                if (isBookmarked) {
                  context.read<BookmarkBloc>().add(
                    RemoveBookmarkEvent(surah!.id, aya.verse),
                  );
                } else {
                  context.read<BookmarkBloc>().add(
                    AddBookmarkEvent(
                      BookmarkModel(
                        surahId: surah!.id,
                        surahName: surah!.nameEnglish,
                        verseId: aya.verse,
                        createdAt: DateTime.now(),
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                isError ? Icons.playlist_remove : Icons.error_outline,
                color: Colors.redAccent,
              ),
              title: Text(
                isError ? 'Unmark Mistake' : 'Mark as Recitation Mistake',
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isError) {
                  context.read<RecitationErrorBloc>().add(
                    RemoveRecitationErrorEvent(surah!.id, aya.verse),
                  );
                } else {
                  context.read<RecitationErrorBloc>().add(
                    AddRecitationErrorEvent(
                      RecitationErrorModel(
                        surahId: surah!.id,
                        surahName: surah!.nameEnglish,
                        verseId: aya.verse,
                        createdAt: DateTime.now(),
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
                    NavigatorService.pushNamed(AppRoutes.helpScreen);
                  },
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 8.h),
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

class _VerseRange {
  final int start;
  final int end;
  final Chapter verse;
  final bool isBadge;
  final bool isBookmarked;
  final bool isError;

  _VerseRange({
    required this.start,
    required this.end,
    required this.verse,
    required this.isBadge,
    required this.isBookmarked,
    required this.isError,
  });
}

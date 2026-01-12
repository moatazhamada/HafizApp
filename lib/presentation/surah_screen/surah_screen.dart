import "package:flutter/gestures.dart";
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
  int? _selectedVerse; // For visual selection feedback

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
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF006754),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
        onPressed: () => NavigatorService.goBack(),
      ),
      // No title - title only shows in expanded FlexibleSpace
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => NavigatorService.pushNamed(AppRoutes.helpScreen),
        ),
        IconButton(
          icon: Icon(
            _isHifzMode ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isHifzMode = !_isHifzMode;
              _revealedVerses.clear();
            });
          },
        ),
        BlocBuilder<BookmarkBloc, BookmarkState>(
          builder: (context, state) {
            bool isBookmarked = false;
            if (state is BookmarkLoaded) {
              isBookmarked = state.bookmarks.any(
                (element) => element.surahId == (surah?.id ?? -1),
              );
            }
            return IconButton(
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
                        verseId: 1,
                        createdAt: DateTime.now(),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildAppBar()),
    );
  }

  Widget _buildBismillah(bool isDark) {
    // Surah 1 (Al-Fatiha): Bismillah is the first Ayah, not pre-text
    // Surah 9 (At-Tawbah): No Bismillah at all
    if (surah?.id == 1 || surah?.id == 9) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: "Amiri",
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF004B40),
        ),
      ),
    );
  }

  Widget _buildSurahList(
    BuildContext context,
    List<Chapter> chapters,
    BookmarkState bookmarkState,
    RecitationErrorState errorState,
    bool isDark,
  ) {
    const double fontSize = 22;
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

    // Build continuous text with inline verse badges
    List<InlineSpan> spans = [];

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
      bool isSelected = _selectedVerse == aya.verse;

      // Styling
      Color? backgroundColor;
      if (isSelected) {
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

      // Add verse text with tap gesture
      final tapRecognizer = TapGestureRecognizer()
        ..onTap = () {
          setState(() {
            _selectedVerse = aya.verse;
          });
          if (_isHifzMode) {
            setState(() {
              if (_revealedVerses.contains(aya.verse)) {
                _revealedVerses.remove(aya.verse);
              } else {
                _revealedVerses.add(aya.verse);
              }
            });
          }
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _selectedVerse = null;
              });
            }
          });
        };

      final longPressRecognizer = LongPressGestureRecognizer()
        ..onLongPress = () {
          setState(() {
            _selectedVerse = aya.verse;
          });
          _showVerseMenu(context, aya, isBookmarked, isRecitationError);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _selectedVerse = null;
              });
            }
          });
        };

      spans.add(
        TextSpan(
          text: "${aya.text} ",
          style: TextStyle(
            fontFamily: "Amiri",
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: effectiveColor,
            backgroundColor: backgroundColor,
            shadows: shadows,
            height: 1.8,
          ),
          recognizer: tapRecognizer,
        ),
      );

      // Also add long press recognizer
      spans.add(TextSpan(text: "", recognizer: longPressRecognizer));

      // Add verse number badge
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              _showVerseMenu(context, aya, isBookmarked, isRecitationError);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
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
                '${aya.verse}',
                style: TextStyle(
                  fontFamily: "Amiri",
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBismillah(isDark),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RichText(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              text: TextSpan(children: spans),
            ),
          ),
        ],
      ),
    );
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
          child: Center(
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
                // Show divider and Bismillah image for all except Surah 1 and 9
                if (surah?.id != 1 && surah?.id != 9) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 1.adaptSize,
                      width: 144.h,
                      color: const Color(0xFFD9D8D8),
                    ),
                  ),
                  CustomImageView(imagePath: ImageConstant.imgBismillah),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

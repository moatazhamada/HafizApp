import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/sajdah_index.dart';
import 'package:hafiz_app/core/utils/surah_name_formatter.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'bismillah_widget.dart';
import 'hifz_mode_overlay.dart';
import 'tafsir_sheet.dart';
import 'verse_menu_sheet.dart';
import 'verse_range.dart';

/// Mutable cache container so [VerseListView] can remain const-constructible.
class VerseStateCache {
  ({Set<int> bookmarkedVerses, Set<int> errorVerses})? value;
  int? bookmarkHash;
  int? errorHash;
}

class VerseListView extends StatelessWidget {
  final List<Verse> chapters;
  final BookmarkState bookmarkState;
  final RecitationErrorState errorState;
  final bool isDark;
  final Surah? surah;
  final bool isHifzMode;
  final Set<int> revealedVerses;
  final int? highlightedVerse;
  final bool showTranslation;
  final Map<int, String> translations;
  final Map<int, GlobalKey> verseKeys;
  final Map<int, GlobalKey> richTextVerseKeys;
  final GlobalKey richTextKey;
  final List<VerseRange> currentVerseRanges;
  final void Function(List<VerseRange>) onUpdateVerseRanges;
  final void Function(int verseNumber) onToggleHifzReveal;
  final void Function(Verse aya) onVerifyRecitation;
  final void Function(int verseNumber) onPlayOnlyVerse;
  final void Function(int verseNumber) onStartFromVerse;

  VerseListView({
    super.key,
    required this.chapters,
    required this.bookmarkState,
    required this.errorState,
    required this.isDark,
    required this.surah,
    required this.isHifzMode,
    required this.revealedVerses,
    required this.highlightedVerse,
    required this.showTranslation,
    required this.translations,
    required this.verseKeys,
    required this.richTextVerseKeys,
    required this.richTextKey,
    required this.currentVerseRanges,
    required this.onUpdateVerseRanges,
    required this.onToggleHifzReveal,
    required this.onVerifyRecitation,
    required this.onPlayOnlyVerse,
    required this.onStartFromVerse,
  });

  void _handleShowVerseMenu(
    BuildContext context,
    Verse aya,
    bool isBookmarked,
    bool isRecitationError,
  ) {
    if (surah == null) return;
    showVerseMenu(
      context,
      verse: aya,
      surahId: surah!.id,
      surahNameEnglish: surah!.nameEnglish,
      isBookmarked: isBookmarked,
      isError: isRecitationError,
      onVerifyRecitation: () => onVerifyRecitation(aya),
      onOpenTafsir: () => showTafsirSheet(
        context,
        surahId: surah!.id,
        surahName: surah!.localizedName(context),
        verseNumber: aya.verseNumber,
      ),
      onReadThisAyah: () => onPlayOnlyVerse(aya.verseNumber),
      onStartFromHere: () => onStartFromVerse(aya.verseNumber),
      bookmarkBloc: context.read<BookmarkBloc>(),
    );
  }

  // Cached verse states to avoid O(n) filtering on every rebuild.
  final VerseStateCache _verseStateCache = VerseStateCache();

  ({Set<int> bookmarkedVerses, Set<int> errorVerses}) _getVerseStates() {
    final surahId = surah?.id ?? -1;

    // Compute cheap hashes to detect state changes
    final bookmarkHash = bookmarkState is BookmarkLoaded
        ? (bookmarkState as BookmarkLoaded).bookmarks.length
        : 0;
    final errorHash = errorState is RecitationErrorLoaded
        ? (errorState as RecitationErrorLoaded).errors.length
        : 0;

    if (_verseStateCache.value != null &&
        _verseStateCache.bookmarkHash == bookmarkHash &&
        _verseStateCache.errorHash == errorHash) {
      return _verseStateCache.value!;
    }

    final bookmarkedVerses = bookmarkState is BookmarkLoaded
        ? (bookmarkState as BookmarkLoaded).bookmarks
              .where((b) => b.surahId == surahId)
              .map((b) => b.verseNumber)
              .toSet()
        : <int>{};
    final errorVerses = errorState is RecitationErrorLoaded
        ? (errorState as RecitationErrorLoaded).errors
              .where((m) => m.surahId == surahId)
              .map((m) => m.verseId)
              .toSet()
        : <int>{};

    _verseStateCache.value = (bookmarkedVerses: bookmarkedVerses, errorVerses: errorVerses);
    _verseStateCache.bookmarkHash = bookmarkHash;
    _verseStateCache.errorHash = errorHash;
    return _verseStateCache.value!;
  }

  @override
  Widget build(BuildContext context) {
    if (PrefUtils().getVerseViewMode()) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BismillahWidget(surahId: surah?.id ?? 0),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildSingleLineContentSliver(context),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16.0)),
        ],
      );
    } else {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BismillahWidget(surahId: surah?.id ?? 0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildRichTextContent(context),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRichTextContent(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = colors.textColor;
    final badgeText = colors.badgeText;

    final verseStates = _getVerseStates();
    final bookmarkedVerseNumbers = verseStates.bookmarkedVerses;
    final errorVerseIds = verseStates.errorVerses;

    List<InlineSpan> spans = [];
    final List<VerseRange> verseRanges = [];
    int currentOffset = 0;

    for (var aya in chapters) {
      bool isBookmarked = bookmarkedVerseNumbers.contains(aya.verseNumber);
      bool isRecitationError = errorVerseIds.contains(aya.verseNumber);

      bool isBlurred =
          isHifzMode && !revealedVerses.contains(aya.verseNumber);
      bool isHighlighted = highlightedVerse == aya.verseNumber;

      Color? backgroundColor;
      if (isHighlighted) {
        backgroundColor = colors.highlightBackground;
      } else if (isRecitationError) {
        backgroundColor = colors.errorBackground;
      } else if (isBookmarked) {
        backgroundColor = colors.bookmarkBackground;
      }

      final Color effectiveColor = isBlurred ? Colors.transparent : textColor;
      final List<Shadow>? shadows = isBlurred
          ? [Shadow(color: textColor, blurRadius: 20.0, offset: Offset.zero)]
          : null;

      String verseText = '${aya.arabicText} ';

      if (aya.verseNumber == 1 && surah?.id != 1) {
        const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
        const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
        if (verseText.startsWith(bismillahPrefix)) {
          verseText = verseText.substring(bismillahPrefix.length).trim();
        } else if (verseText.startsWith(bismillahSimple)) {
          verseText = verseText.substring(bismillahSimple.length).trim();
        }
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            key: richTextVerseKeys.putIfAbsent(
              aya.verseNumber,
              () => GlobalKey(debugLabel: 'verse_anchor_${aya.verseNumber}'),
            ),
            width: 0,
            height: 0,
          ),
        ),
      );
      currentOffset += 1;

      verseRanges.add(
        VerseRange(
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
          text: '$verseText\u200f',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: PrefUtils().getQuranFontSize(),
            fontWeight: FontWeight.normal,
            color: effectiveColor,
            backgroundColor: backgroundColor,
            shadows: shadows,
            height: 2.2,
          ),
        ),
      );
      currentOffset += verseText.length + 1;

      final verseMarker =
          ' \u06dd${aya.verseNumber.toLocalizedNumber(context)} ';
      verseRanges.add(
        VerseRange(
          start: currentOffset,
          end: currentOffset + verseMarker.length,
          verse: aya,
          isBadge: true,
          isBookmarked: isBookmarked,
          isError: isRecitationError,
        ),
      );

      spans.add(
        TextSpan(
          text: verseMarker,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: PrefUtils().getQuranFontSize() - 4,
            fontWeight: FontWeight.bold,
            color: badgeText,
            height: 2.2,
          ),
        ),
      );
      currentOffset += verseMarker.length;

      if (isSajdahVerse(surah?.id ?? 0, aya.verseNumber)) {
        const sajdahMarker = ' \u06de ';
        verseRanges.add(
          VerseRange(
            start: currentOffset,
            end: currentOffset + sajdahMarker.length,
            verse: aya,
            isBookmarked: isBookmarked,
            isError: isRecitationError,
          ),
        );
        spans.add(
          TextSpan(
            text: sajdahMarker,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: PrefUtils().getQuranFontSize() - 4,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).statBookmark,
              height: 2.2,
            ),
          ),
        );
        currentOffset += sajdahMarker.length;
      }

      spans.add(const TextSpan(text: '\u200f'));
      currentOffset += 1;

      if (showTranslation && translations[aya.verseNumber] != null) {
        final translationText = translations[aya.verseNumber]!;
        verseRanges.add(
          VerseRange(
            start: currentOffset,
            end: currentOffset + 1,
            verse: aya,
            isBadge: false,
            isBookmarked: isBookmarked,
            isError: isRecitationError,
          ),
        );
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 6.0, bottom: 14.0),
              child: Text(
                translationText,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        );
        currentOffset += 1;
      }
    }

    final textSpan = TextSpan(children: spans);
    onUpdateVerseRanges(verseRanges);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Semantics(
          label: 'lbl_quran_text'.tr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final range = _findRange(details.localPosition, verseRanges);
              if (range == null) return;

              if (isHifzMode) {
                onToggleHifzReveal(range.verse.verseNumber);
              } else {
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    range.verse.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _handleShowVerseMenu(
                  context,
                  range.verse,
                  range.isBookmarked,
                  range.isError,
                );
              }
            },
            onLongPressStart: (details) {
              if (isHifzMode) {
                final range = _findRange(details.localPosition, verseRanges);
                if (range != null) {
                  _handleShowVerseMenu(
                    context,
                    range.verse,
                    range.isBookmarked,
                    range.isError,
                  );
                }
              }
            },
            child: RichText(
              key: richTextKey,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              text: textSpan,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
            ),
          ),
        );
      },
    );
  }

  VerseRange? _findRange(Offset localPosition, List<VerseRange> ranges) {
    final RenderObject? renderObject = richTextKey.currentContext
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

  Widget _buildSingleLineContentSliver(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = colors.textColor;
    final badgeBorder = colors.badgeBorder;
    final badgeText = colors.badgeText;
    final badgeGradient = colors.badgeGradient;

    final verseStates = _getVerseStates();
    final bookmarkedVerseNumbers = verseStates.bookmarkedVerses;
    final errorVerseIds = verseStates.errorVerses;

    return SliverList.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final aya = chapters[index];
        bool isBookmarked = bookmarkedVerseNumbers.contains(aya.verseNumber);
        bool isRecitationError = errorVerseIds.contains(aya.verseNumber);

        bool isBlurred =
            isHifzMode && !revealedVerses.contains(aya.verseNumber);
        bool isHighlighted = highlightedVerse == aya.verseNumber;

        Color? backgroundColor;
        if (isHighlighted) {
          backgroundColor = colors.highlightBackground;
        } else if (isRecitationError) {
          backgroundColor = colors.errorBackground;
        } else if (isBookmarked) {
          backgroundColor = colors.bookmarkBackground;
        }

        String verseText = aya.arabicText;
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

        final surahName = surah != null
            ? (Localizations.localeOf(context).languageCode == 'ar'
                ? surah!.nameArabic
                : surah!.nameEnglish)
            : '';

        return Semantics(
          button: true,
          label: surahName.isNotEmpty
              ? 'lbl_semantics_verse_of'
                  .tr
                  .replaceAll('{verse}', '${aya.verseNumber}')
                  .replaceAll('{surah}', surahName)
              : '${'lbl_ayah'.tr} ${aya.verseNumber}',
          textDirection: TextDirection.rtl,
          child: GestureDetector(
            onTap: () {
              if (isHifzMode) {
                onToggleHifzReveal(aya.verseNumber);
              } else {
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    aya.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _handleShowVerseMenu(
                  context,
                  aya,
                  isBookmarked,
                  isRecitationError,
                );
              }
            },
            onLongPress: () {
              if (isHifzMode) {
                _handleShowVerseMenu(
                  context,
                  aya,
                  isBookmarked,
                  isRecitationError,
                );
              }
            },
            child: Container(
              key: verseKeys.putIfAbsent(
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
                            ? AppColors.of(context).statBookmark.withValues(alpha: 0.5)
                            : isRecitationError
                            ? AppColors.of(context).needsReviewStatus.withValues(alpha: 0.3)
                            : AppColors.of(context).statBookmark.withValues(alpha: 0.3),
                        width: isHighlighted ? 2 : 1,
                      )
                    : null,
              ),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  HifzModeOverlay(
                    text: verseText,
                    isBlurred: isBlurred,
                    textColor: textColor,
                    baseStyle: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: PrefUtils().getQuranFontSize(),
                      fontWeight: FontWeight.normal,
                      color: textColor,
                      height: 2.2,
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                  if (isSajdahVerse(surah?.id ?? 0, aya.verseNumber))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: 'lbl_sajdah'.tr,
                        child: Text(
                          '\u06de',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: PrefUtils().getQuranFontSize() - 6,
                            fontWeight: FontWeight.bold,
                            color: AppColors.of(context).statBookmark,
                          ),
                        ),
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
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                  if (showTranslation &&
                      translations[aya.verseNumber] != null)
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text(
                          translations[aya.verseNumber]!,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


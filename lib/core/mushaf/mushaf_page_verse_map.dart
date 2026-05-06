import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';

class MushafPageVerseMap {
  static const int _headerReduction = 2;

  static List<MushafPageRange> getVersesForPage(int page) {
    if (page < 1 || page > MushafPageIndex.totalPages) return [];

    final ranges = <MushafPageRange>[];

    for (int i = 0; i < 114; i++) {
      final surahStartPage = MushafPageIndex.surahStartPages[i];
      if (surahStartPage > page) break;

      final nextSurahStartPage = i < 113
          ? MushafPageIndex.surahStartPages[i + 1]
          : MushafPageIndex.totalPages + 1;
      if (nextSurahStartPage <= page) continue;

      final surahId = i + 1;
      final verseCount = MushafPageIndex.surahVerseCounts[i];

      if (surahStartPage == nextSurahStartPage) {
        ranges.add(MushafPageRange(
          surahId: surahId,
          startVerse: 1,
          endVerse: verseCount,
        ));
      } else {
        final pagesInSurah = nextSurahStartPage - surahStartPage;
        final pageOffset = page - surahStartPage;
        final isFirstPage = pageOffset == 0;

        final effectivePages = isFirstPage
            ? pagesInSurah - (_headerReduction ~/ 2)
            : pagesInSurah;

        final rawStart = isFirstPage
            ? 1
            : (pageOffset * verseCount / effectivePages).floor() + 1;
        final rawEnd =
            ((pageOffset + 1) * verseCount / effectivePages).ceil();

        ranges.add(MushafPageRange(
          surahId: surahId,
          startVerse: rawStart.clamp(1, verseCount),
          endVerse: rawEnd.clamp(1, verseCount),
        ));
      }
    }
    return ranges;
  }
}

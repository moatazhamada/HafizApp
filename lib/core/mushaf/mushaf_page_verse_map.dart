import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';

class MushafPageVerseMap {
  static const int _headerReduction = 2;

  /// Returns the verse ranges that appear on [page].
  /// Uses the loaded JSON index when available; falls back to a
  /// proportional estimation from the hardcoded arrays otherwise.
  /// [totalPages] is the page count of the active mushaf type (default 604).
  static List<MushafPageRange> getVersesForPage(
    int page, {
    int totalPages = 604,
  }) {
    if (page < 1 || page > totalPages) return [];

    // For non-Madani types, map the page to a Madani-equivalent page
    if (totalPages != MushafPageIndex.totalPages) {
      final madaniPage = (page / totalPages * MushafPageIndex.totalPages)
          .round()
          .clamp(1, MushafPageIndex.totalPages);
      return _getVersesInternal(madaniPage);
    }

    return _getVersesInternal(page);
  }

  static List<MushafPageRange> _getVersesInternal(int page) {
    if (MushafPageIndex.isLoaded) return _fromJson(page);
    return _fromFallback(page);
  }

  // ─── JSON-based lookup (accurate) ───────────────────────────────

  static List<MushafPageRange> _fromJson(int page) {
    final data = MushafPageIndex.getPageData(page);
    if (data == null) return [];

    final ranges = <MushafPageRange>[];

    // Single-surah page (most common).
    if (data.surahId == data.endSurahId) {
      ranges.add(
        MushafPageRange(
          surahId: data.surahId,
          startVerse: data.startVerse,
          endVerse: data.endVerse,
        ),
      );
      return ranges;
    }

    // Two-surah page: the page data covers the *first* surah's portion,
    // and we need to find the remaining verses from the next page entry
    // (or the next surah's start).
    ranges.add(
      MushafPageRange(
        surahId: data.surahId,
        startVerse: data.startVerse,
        endVerse: data.endVerse,
      ),
    );

    // Second surah starts at verse 1 on this page.
    final nextData = MushafPageIndex.getPageData(page + 1);
    final endSurahId = data.endSurahId;
    if (nextData != null && nextData.surahId == endSurahId) {
      ranges.add(
        MushafPageRange(
          surahId: endSurahId,
          startVerse: 1,
          endVerse: nextData.startVerse - 1,
        ),
      );
    } else {
      // The second surah's entire portion fits on this page.
      final verseCount = MushafPageIndex.getVerseCount(endSurahId);
      ranges.add(
        MushafPageRange(
          surahId: endSurahId,
          startVerse: 1,
          endVerse: verseCount,
        ),
      );
    }

    return ranges;
  }

  // ─── Fallback proportional estimation ───────────────────────────

  static List<MushafPageRange> _fromFallback(int page) {
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

      final pagesInSurah = nextSurahStartPage - surahStartPage;
      if (pagesInSurah <= 0) {
        // Degenerate entry (e.g. multiple surahs share the same
        // start page in the fallback array) — assign all verses.
        ranges.add(
          MushafPageRange(
            surahId: surahId,
            startVerse: 1,
            endVerse: verseCount,
          ),
        );
        continue;
      }

      final pageOffset = page - surahStartPage;
      final isFirstPage = pageOffset == 0;

      final effectivePages = isFirstPage
          ? pagesInSurah - (_headerReduction ~/ 2)
          : pagesInSurah;
      if (effectivePages <= 0) {
        ranges.add(
          MushafPageRange(
            surahId: surahId,
            startVerse: 1,
            endVerse: verseCount,
          ),
        );
        continue;
      }

      final rawStart = isFirstPage
          ? 1
          : (pageOffset * verseCount / effectivePages).floor() + 1;
      final rawEnd = ((pageOffset + 1) * verseCount / effectivePages).ceil();

      ranges.add(
        MushafPageRange(
          surahId: surahId,
          startVerse: rawStart.clamp(1, verseCount),
          endVerse: rawEnd.clamp(1, verseCount),
        ),
      );
    }
    return ranges;
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'quran_surah.dart';

/// Mushaf Page Index - Maps Madani Mushaf pages (1-604) to Surah/verse ranges.
/// Data is loaded from assets/quran/mushaf_page_index.json.
class MushafPageIndex {
  static const int totalPages = 604;
  static const String _assetPath = 'assets/quran/mushaf_page_index.json';

  static bool _isLoaded = false;
  static List<List<dynamic>> _pagesData = const [];

  /// Start of page
  final int pageNumber;
  final int surahId;
  final int startVerse;

  /// End of page (can be in the same or a later surah)
  final int endSurahId;
  final int endVerse;

  final String surahNameAr;
  final String surahNameEn;

  const MushafPageIndex({
    required this.pageNumber,
    required this.surahId,
    required this.startVerse,
    required this.endSurahId,
    required this.endVerse,
    required this.surahNameAr,
    required this.surahNameEn,
  });

  static Future<void> loadPageDataFromAsset() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _pagesData = await compute(_parseMushafPages, jsonString);
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading Mushaf page data: $e');
      // Initialize with empty data to prevent app crash, or rethrow if critical
      _pagesData = [];
      _isLoaded = true;
    }
  }

  static List<List<dynamic>> _parseMushafPages(String jsonString) {
    final jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) {
          final row = item as List<dynamic>;
          return <dynamic>[
            (row[0] as num).toInt(),
            (row[1] as num).toInt(),
            (row[2] as num).toInt(),
            (row[3] as num).toInt(),
            (row[4] as num).toInt(),
            row[5] as String,
            row[6] as String,
          ];
        })
        .toList(growable: false);
  }

  static void _ensureLoaded() {
    if (!_isLoaded) {
      throw StateError(
        'MushafPageIndex not loaded. Call MushafPageIndex.loadPageDataFromAsset() during app startup.',
      );
    }
  }

  static MushafPageIndex _toPage(List<dynamic> data) {
    return MushafPageIndex(
      pageNumber: data[0] as int,
      surahId: data[1] as int,
      startVerse: data[2] as int,
      endSurahId: data[3] as int,
      endVerse: data[4] as int,
      surahNameAr: data[5] as String,
      surahNameEn: data[6] as String,
    );
  }

  /// Get all pages data.
  static List<MushafPageIndex> getAllPages() {
    _ensureLoaded();
    return _pagesData.map(_toPage).toList(growable: false);
  }

  /// Get page by page number (1-604).
  static MushafPageIndex? getPage(int pageNumber) {
    _ensureLoaded();
    if (pageNumber < 1 || pageNumber > totalPages) return null;
    final data = _pagesData[pageNumber - 1];
    return _toPage(data);
  }

  /// Find page number for a specific verse.
  static int? findPageForVerse(int surahId, int verseNumber) {
    _ensureLoaded();
    for (final page in _pagesData) {
      final startSurah = page[1] as int;
      final startVerse = page[2] as int;
      final endSurah = page[3] as int;
      final endVerse = page[4] as int;

      if (surahId < startSurah || surahId > endSurah) {
        continue;
      }

      final isInSingleSurahRange =
          startSurah == endSurah &&
          surahId == startSurah &&
          verseNumber >= startVerse &&
          verseNumber <= endVerse;
      if (isInSingleSurahRange) return page[0] as int;

      if (startSurah != endSurah) {
        if (surahId == startSurah && verseNumber >= startVerse) {
          return page[0] as int;
        }
        if (surahId == endSurah && verseNumber <= endVerse) {
          return page[0] as int;
        }
        if (surahId > startSurah && surahId < endSurah) {
          return page[0] as int;
        }
      }
    }
    return null;
  }

  /// Get all verses covered by a specific page.
  static List<MushafVerse> getVersesForPage(int pageNumber) {
    final page = getPage(pageNumber);
    if (page == null) return [];

    final verses = <MushafVerse>[];
    for (int s = page.surahId; s <= page.endSurahId; s++) {
      final surah = QuranIndex.quranSurahs.firstWhere(
        (q) => q.id == s,
        orElse: () => QuranIndex.quranSurahs.first,
      );
      final fromVerse = s == page.surahId ? page.startVerse : 1;
      final toVerse = (s == page.endSurahId ? page.endVerse : surah.verseCount)
          .clamp(1, surah.verseCount);
      for (int v = fromVerse; v <= toVerse; v++) {
        verses.add(
          MushafVerse(surahId: s, verseNumber: v, pageNumber: pageNumber),
        );
      }
    }
    return verses;
  }

  /// Check if page starts a Surah.
  bool get isSurahStart => startVerse == 1;

  /// Check if page contains Bismillah (start of Surah, except 1 and 9).
  bool get containsBismillah => isSurahStart && surahId != 1 && surahId != 9;
}

/// Represents a verse within a Mushaf page.
class MushafVerse {
  final int surahId;
  final int verseNumber;
  final int pageNumber;

  const MushafVerse({
    required this.surahId,
    required this.verseNumber,
    required this.pageNumber,
  });
}

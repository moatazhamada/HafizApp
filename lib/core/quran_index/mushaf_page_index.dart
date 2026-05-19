import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class MushafPageRange {
  final int surahId;
  final int startVerse;
  final int endVerse;

  const MushafPageRange({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
  });
}

/// Per-page entry loaded from assets/quran/mushaf_page_index.json.
class MushafPageData {
  final int pageNumber;
  final int surahId;
  final int startVerse;
  final int endSurahId;
  final int endVerse;
  final String surahNameArabic;
  final String surahNameEnglish;

  const MushafPageData({
    required this.pageNumber,
    required this.surahId,
    required this.startVerse,
    required this.endSurahId,
    required this.endVerse,
    required this.surahNameArabic,
    required this.surahNameEnglish,
  });

  factory MushafPageData.fromJson(List<dynamic> json) {
    return MushafPageData(
      pageNumber: json[0] as int,
      surahId: json[1] as int,
      startVerse: json[2] as int,
      endSurahId: json[3] as int,
      endVerse: json[4] as int,
      surahNameArabic: json[5] as String,
      surahNameEnglish: json[6] as String,
    );
  }
}

class MushafPageIndex {
  static const int totalPages = 604;

  /// JSON-loaded page data (populated by [loadFromAsset]).
  static List<MushafPageData> _pages = const [];
  static bool _loaded = false;

  /// Precomputed cumulative verse offsets for O(1) absolute verse ID lookups.
  /// _verseOffsets[surahId] = total verses before surahId (1-based indexing).
  static final List<int> _verseOffsets = List.filled(115, 0);
  static bool _offsetsComputed = false;

  static bool get isLoaded => _loaded;

  /// Load page index from the bundled JSON asset. Call once at startup.
  static Future<void> loadFromAsset() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/quran/mushaf_page_index.json',
      );
      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      _pages = list
          .map((e) => MushafPageData.fromJson(e as List<dynamic>))
          .toList();
      _loaded = true;
    } catch (e) {
      // Keep fallback hardcoded arrays usable
      _loaded = false;
    }
  }

  // ─── Fallback arrays (used when JSON hasn't loaded yet) ─────────

  static const List<int> surahStartPages = [
    1,
    2,
    21,
    50,
    77,
    106,
    128,
    151,
    177,
    187,
    208,
    221,
    235,
    249,
    255,
    267,
    282,
    293,
    305,
    312,
    322,
    332,
    342,
    350,
    359,
    367,
    377,
    385,
    396,
    404,
    411,
    415,
    418,
    428,
    434,
    440,
    446,
    453,
    458,
    467,
    477,
    483,
    489,
    496,
    499,
    502,
    507,
    511,
    515,
    518,
    520,
    523,
    525,
    528,
    531,
    534,
    537,
    542,
    545,
    549,
    551,
    553,
    554,
    556,
    558,
    561,
    564,
    570,
    574,
    577,
    581,
    583,
    585,
    587,
    591,
    594,
    596,
    599,
    602,
    603,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
    604,
  ];

  static List<int> get surahVerseCounts => _surahVerseCounts;

  static const List<int> _surahVerseCounts = [
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6,
  ];

  // ─── Lookup helpers ─────────────────────────────────────────────

  static int getVerseCount(int surahId) {
    if (surahId < 1 || surahId > 114) {
      Logger.warning('Out-of-range surahId: $surahId', feature: 'MushafPageIndex');
      return 0;
    }
    return _surahVerseCounts[surahId - 1];
  }

  /// Compute cumulative verse offsets for O(1) absolute verse ID lookups.
  /// Call once at startup (e.g. after [loadFromAsset]).
  static void _computeVerseOffsets() {
    if (_offsetsComputed) return;
    int offset = 0;
    for (int i = 0; i < _surahVerseCounts.length; i++) {
      _verseOffsets[i + 1] = offset;
      offset += _surahVerseCounts[i];
    }
    _offsetsComputed = true;
  }

  /// Return the 1-based absolute verse ID across the entire Quran.
  /// Example: Surah 2, verse 1 → 8 (after Al-Fatiha's 7 verses).
  static int getAbsoluteVerseId(int surahId, int verseNumber) {
    if (surahId < 1 || surahId > 114) return 0;
    _computeVerseOffsets();
    return _verseOffsets[surahId] + verseNumber;
  }

  static int getSurahForPage(int page) {
    if (page < 1 || page > totalPages) return 1;
    if (_loaded && page <= _pages.length) {
      return _pages[page - 1].surahId;
    }
    for (int i = surahStartPages.length - 1; i >= 0; i--) {
      if (surahStartPages[i] <= page) return i + 1;
    }
    return 1;
  }

  static int getPageForSurah(int surahId) {
    if (surahId < 1 || surahId > 114) return 1;
    if (_loaded) {
      for (final page in _pages) {
        if (page.surahId == surahId) return page.pageNumber;
      }
    }
    return surahStartPages[surahId - 1];
  }

  static MushafPageData? getPageData(int page) {
    if (_loaded && page >= 1 && page <= _pages.length) {
      return _pages[page - 1];
    }
    return null;
  }

  static int getJuzForPage(int page) {
    if (page < 1 || page > totalPages) return 1;
    const juzPages = [
      1,
      21,
      42,
      62,
      82,
      106,
      127,
      151,
      177,
      187,
      208,
      224,
      249,
      255,
      266,
      282,
      293,
      305,
      322,
      342,
      360,
      382,
      399,
      414,
      426,
      440,
      452,
      468,
      486,
      516,
    ];
    for (int i = juzPages.length - 1; i >= 0; i--) {
      if (juzPages[i] <= page) return i + 1;
    }
    return 1;
  }

  static int getPageForJuz(int juz) {
    if (juz < 1 || juz > 30) return 1;
    const juzPages = [
      1,
      21,
      42,
      62,
      82,
      106,
      127,
      151,
      177,
      187,
      208,
      224,
      249,
      255,
      266,
      282,
      293,
      305,
      322,
      342,
      360,
      382,
      399,
      414,
      426,
      440,
      452,
      468,
      486,
      516,
    ];
    return juzPages[juz - 1];
  }

  static int getPageForJuzIndex(int juzIndex) {
    if (juzIndex < 0 || juzIndex > 30) return 1;
    return getPageForJuz(juzIndex);
  }

  static int getSurahForJuz(int juz) {
    if (juz < 1 || juz > 30) return 1;
    const juzSurahs = [
      1,
      2,
      2,
      3,
      4,
      4,
      5,
      6,
      7,
      8,
      9,
      11,
      12,
      15,
      17,
      18,
      21,
      23,
      25,
      27,
      29,
      33,
      36,
      39,
      41,
      46,
      51,
      58,
      67,
      78,
    ];
    return juzSurahs[juz - 1];
  }

  static int getPageInfo(int page) => getSurahForPage(page);
}

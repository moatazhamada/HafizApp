class MushafPageRange {
  final int startVerse;
  final int endVerse;

  const MushafPageRange({required this.startVerse, required this.endVerse});
}

class MushafPageData {
  final int surahId;
  final String surahNameArabic;
  final String surahNameEnglish;
  final MushafPageRange? juzStart;
  final MushafPageRange? range;

  const MushafPageData({
    required this.surahId,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    this.juzStart,
    this.range,
  });
}

class MushafPageIndex {
  static const int totalPages = 604;

  static const List<int> _surahStartPages = [
    1,
    2,
    21,
    50,
    77,
    106,
    128,
    142,
    151,
    158,
    177,
    187,
    206,
    208,
    224,
    227,
    242,
    249,
    255,
    266,
    281,
    282,
    293,
    305,
    312,
    322,
    331,
    342,
    350,
    360,
    364,
    367,
    370,
    377,
    382,
    386,
    393,
    399,
    404,
    410,
    414,
    418,
    420,
    423,
    426,
    428,
    432,
    434,
    440,
    446,
    448,
    450,
    452,
    454,
    456,
    459,
    462,
    465,
    468,
    472,
    475,
    477,
    479,
    482,
    484,
    486,
    489,
    492,
    496,
    499,
    501,
    503,
    504,
    506,
    508,
    510,
    512,
    514,
    516,
    518,
    519,
    520,
    522,
    523,
    525,
    527,
    529,
    530,
    531,
    533,
    534,
    536,
    538,
    539,
    541,
    542,
    544,
    545,
    547,
    549,
    550,
    551,
    553,
    554,
    556,
    558,
    560,
    561,
    562,
    564,
    566,
    568,
    570,
    571,
    572,
    574,
    575,
    577,
    578,
    580,
  ];

  static int getSurahForPage(int page) {
    if (page < 1 || page > totalPages) return 1;
    for (int i = _surahStartPages.length - 1; i >= 0; i--) {
      if (_surahStartPages[i] <= page) return i + 1;
    }
    return 1;
  }

  static int getPageForSurah(int surahId) {
    if (surahId < 1 || surahId > 114) return 1;
    return _surahStartPages[surahId - 1];
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
}

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
    1, // 1. Al-Fatihah
    2, // 2. Al-Baqarah
    21, // 3. Ali 'Imran
    50, // 4. An-Nisa
    77, // 5. Al-Ma'idah
    106, // 6. Al-An'am
    128, // 7. Al-A'raf
    151, // 8. Al-Anfal
    177, // 9. At-Tawbah
    187, // 10. Yunus
    208, // 11. Hud
    221, // 12. Yusuf
    235, // 13. Ar-Ra'd
    249, // 14. Ibrahim
    255, // 15. Al-Hijr
    267, // 16. An-Nahl
    282, // 17. Al-Isra
    293, // 18. Al-Kahf
    305, // 19. Maryam
    312, // 20. Taha
    322, // 21. Al-Anbya
    332, // 22. Al-Hajj
    342, // 23. Al-Mu'minun
    350, // 24. An-Nur
    359, // 25. Al-Furqan
    367, // 26. Ash-Shu'ara
    377, // 27. An-Naml
    385, // 28. Al-Qasas
    396, // 29. Al-Ankabut
    404, // 30. Ar-Rum
    411, // 31. Luqman
    415, // 32. As-Sajdah
    418, // 33. Al-Ahzab
    428, // 34. Saba
    434, // 35. Fatir
    440, // 36. Ya-Sin
    446, // 37. As-Saffat
    453, // 38. Sad
    458, // 39. Az-Zumar
    467, // 40. Ghafir
    477, // 41. Fussilat
    483, // 42. Ash-Shuraa
    489, // 43. Az-Zukhruf
    496, // 44. Ad-Dukhan
    499, // 45. Al-Jathiyah
    502, // 46. Al-Ahqaf
    507, // 47. Muhammad
    511, // 48. Al-Fath
    515, // 49. Al-Hujurat
    518, // 50. Qaf
    520, // 51. Adh-Dhariyat
    523, // 52. At-Tur
    525, // 53. An-Najm
    528, // 54. Al-Qamar
    531, // 55. Ar-Rahman
    534, // 56. Al-Waqi'ah
    537, // 57. Al-Hadid
    542, // 58. Al-Mujadila
    545, // 59. Al-Hashr
    549, // 60. Al-Mumtahanah
    551, // 61. As-Saf
    553, // 62. Al-Jumu'ah
    554, // 63. Al-Munafiqun
    556, // 64. At-Taghabun
    558, // 65. At-Talaq
    561, // 66. At-Tahrim
    564, // 67. Al-Mulk
    570, // 68. Al-Qalam
    574, // 69. Al-Haqqah
    577, // 70. Al-Ma'arij
    581, // 71. Nuh
    583, // 72. Al-Jinn
    585, // 73. Al-Muzzammil
    587, // 74. Al-Muddaththir
    591, // 75. Al-Qiyamah
    594, // 76. Al-Insan
    596, // 77. Al-Mursalat
    599, // 78. An-Naba
    602, // 79. An-Nazi'at
    604, // 80. 'Abasa
    604, // 81. At-Takwir
    601, // 82. Al-Infitar
    600, // 83. Al-Mutaffifin
    602, // 84. Al-Inshiqaq
    604, // 85. Al-Buruj
    604, // 86. At-Tariq
    604, // 87. Al-A'la
    604, // 88. Al-Ghashiyah
    604, // 89. Al-Fajr
    604, // 90. Al-Balad
    604, // 91. Ash-Shams
    604, // 92. Al-Layl
    604, // 93. Ad-Duhaa
    604, // 94. Ash-Sharh
    604, // 95. At-Tin
    604, // 96. Al-Alaq
    604, // 97. Al-Qadr
    604, // 98. Al-Bayyinah
    604, // 99. Az-Zalzalah
    604, // 100. Al-Adiyat
    604, // 101. Al-Qari'ah
    604, // 102. At-Takathur
    604, // 103. Al-Asr
    604, // 104. Al-Humazah
    604, // 105. Al-Fil
    604, // 106. Quraysh
    604, // 107. Al-Ma'un
    604, // 108. Al-Kawthar
    604, // 109. Al-Kafirun
    604, // 110. An-Nasr
    604, // 111. Al-Masad
    604, // 112. Al-Ikhlas
    604, // 113. Al-Falaq
    604, // 114. An-Nas
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

  static List<MushafPageRange> getVersesForPage(int page) {
    if (page < 1 || page > totalPages) return [];

    final List<MushafPageRange> ranges = [];
    final surahId = getSurahForPage(page);
    final surahStartPage = _surahStartPages[surahId - 1];
    final nextSurahId = surahId < 114 ? surahId + 1 : 114;
    final nextSurahStartPage = surahId < 114
        ? _surahStartPages[nextSurahId - 1]
        : totalPages + 1;
    final verseCount = _surahVerseCounts[surahId - 1];
    final surahEndPage = nextSurahStartPage - 1;
    final pagesInSurah = surahEndPage - surahStartPage + 1;

    if (pagesInSurah <= 0 || verseCount <= 0) {
      ranges.add(
        MushafPageRange(surahId: surahId, startVerse: 1, endVerse: verseCount),
      );
      return ranges;
    }

    final pageOffset = page - surahStartPage;
    final startVerse = (pageOffset * verseCount / pagesInSurah).floor() + 1;
    final endVerse = ((pageOffset + 1) * verseCount / pagesInSurah).ceil();

    ranges.add(
      MushafPageRange(
        surahId: surahId,
        startVerse: startVerse.clamp(1, verseCount),
        endVerse: endVerse.clamp(1, verseCount),
      ),
    );

    if (nextSurahStartPage == page + 1 && surahId < 114) {
      final nextVerseCount = _surahVerseCounts[nextSurahId - 1];
      if (nextVerseCount > 0) {
        final nextEndPage = nextSurahId < 114
            ? _surahStartPages[nextSurahId] - 1
            : totalPages;
        final nextPagesInSurah = nextEndPage - (page + 1) + 1;
        if (nextPagesInSurah > 0) {
          ranges.add(
            MushafPageRange(
              surahId: nextSurahId,
              startVerse: 1,
              endVerse: (nextVerseCount / nextPagesInSurah).ceil().clamp(
                1,
                nextVerseCount,
              ),
            ),
          );
        }
      }
    }

    return ranges;
  }
}

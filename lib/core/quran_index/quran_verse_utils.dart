/// Verse counts for each of the 114 surahs, ordered by surah number.
const List<int> surahVerseCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
  128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34,
  30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 210, 37, 29, 18, 45,
  60, 49, 14, 38, 30, 11, 5, 19, 58, 29, 22, 35, 39, 7, 31, 14, 38, 10,
  11, 52, 15, 23, 12, 28, 23, 19, 35, 8, 56, 59, 30, 20, 48, 29, 3, 10,
  8, 26, 22, 24, 13, 18, 10, 16, 25, 33, 25, 8, 43, 8, 19, 5, 8, 8, 11,
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
];

/// Compute the absolute verse number (1-based across the entire Quran)
/// for a given surah and verse-within-surah.
int absoluteVerseNumber(int surahId, int verseInSurah) {
  int total = 0;
  for (int i = 0; i < surahId - 1; i++) {
    total += surahVerseCounts[i];
  }
  return total + verseInSurah;
}

int getSurahVerseCount(int surahId) {
  if (surahId < 1 || surahId > 114) return 0;
  return surahVerseCounts[surahId - 1];
}

const _medinanSurahs = {
  2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 55, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 110
};

bool isMeccan(int surahId) {
  return !_medinanSurahs.contains(surahId);
}

String getRevelationType(int surahId) {
  return isMeccan(surahId) ? 'Meccan' : 'Medinan';
}

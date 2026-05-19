import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';

List<int> get surahVerseCounts => MushafPageIndex.surahVerseCounts;

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

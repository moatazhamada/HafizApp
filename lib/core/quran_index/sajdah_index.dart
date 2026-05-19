/// Index of Sajdah Tilawa (prostration of recitation) verses in the Quran.
///
/// There are 15 agreed-upon positions across 14 surahs.
/// Surah 22 (Al-Hajj) contains two positions (verses 18 and 77).
/// Some scholars consider verse 22:77 optional, but it is included here
/// to ensure users are not missing a potential sajdah.
const Map<int, List<int>> sajdahVerses = {
  7: [206], // Al-A'raf
  13: [15], // Ar-Ra'd
  16: [49], // An-Nahl
  17: [109], // Al-Isra
  19: [58], // Maryam
  22: [18, 77], // Al-Hajj
  25: [60], // Al-Furqan
  27: [26], // An-Naml
  32: [15], // As-Sajdah
  38: [24], // Sad
  41: [38], // Fussilat
  53: [62], // An-Najm
  84: [21], // Al-Inshiqaq
  96: [19], // Al-Alaq
};

/// Returns true if the given [surahId] and [verseNumber] requires
/// Sajdah Tilawa (prostration of recitation).
bool isSajdahVerse(int surahId, int verseNumber) {
  final verses = sajdahVerses[surahId];
  if (verses == null) return false;
  return verses.contains(verseNumber);
}

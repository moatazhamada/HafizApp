/// Juz (Para) index for the Quran
/// 
/// Each Juz contains approximately 1/30th of the Quran.
/// This mapping helps navigate to specific Juz positions.
library;

class JuzInfo {
  final int juzNumber;
  final int startSurahId;
  final int startVerseNumber;
  final String startSurahNameEn;
  final String startSurahNameAr;

  const JuzInfo({
    required this.juzNumber,
    required this.startSurahId,
    required this.startVerseNumber,
    required this.startSurahNameEn,
    required this.startSurahNameAr,
  });
}

/// Complete Juz index mapping Juz 1-30 to their starting positions
class JuzIndex {
  static const List<JuzInfo> allJuz = [
    JuzInfo(
      juzNumber: 1,
      startSurahId: 1,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Fatiha',
      startSurahNameAr: 'الفاتحة',
    ),
    JuzInfo(
      juzNumber: 2,
      startSurahId: 2,
      startVerseNumber: 142,
      startSurahNameEn: 'Al-Baqarah',
      startSurahNameAr: 'البقرة',
    ),
    JuzInfo(
      juzNumber: 3,
      startSurahId: 2,
      startVerseNumber: 253,
      startSurahNameEn: 'Al-Baqarah',
      startSurahNameAr: 'البقرة',
    ),
    JuzInfo(
      juzNumber: 4,
      startSurahId: 3,
      startVerseNumber: 93,
      startSurahNameEn: 'Aal-E-Imran',
      startSurahNameAr: 'آل عمران',
    ),
    JuzInfo(
      juzNumber: 5,
      startSurahId: 4,
      startVerseNumber: 24,
      startSurahNameEn: 'An-Nisa',
      startSurahNameAr: 'النساء',
    ),
    JuzInfo(
      juzNumber: 6,
      startSurahId: 4,
      startVerseNumber: 148,
      startSurahNameEn: 'An-Nisa',
      startSurahNameAr: 'النساء',
    ),
    JuzInfo(
      juzNumber: 7,
      startSurahId: 5,
      startVerseNumber: 82,
      startSurahNameEn: 'Al-Ma\'idah',
      startSurahNameAr: 'المائدة',
    ),
    JuzInfo(
      juzNumber: 8,
      startSurahId: 6,
      startVerseNumber: 111,
      startSurahNameEn: 'Al-An\'am',
      startSurahNameAr: 'الأنعام',
    ),
    JuzInfo(
      juzNumber: 9,
      startSurahId: 7,
      startVerseNumber: 88,
      startSurahNameEn: 'Al-A\'raf',
      startSurahNameAr: 'الأعراف',
    ),
    JuzInfo(
      juzNumber: 10,
      startSurahId: 8,
      startVerseNumber: 41,
      startSurahNameEn: 'Al-Anfal',
      startSurahNameAr: 'الأنفال',
    ),
    JuzInfo(
      juzNumber: 11,
      startSurahId: 9,
      startVerseNumber: 93,
      startSurahNameEn: 'At-Tawbah',
      startSurahNameAr: 'التوبة',
    ),
    JuzInfo(
      juzNumber: 12,
      startSurahId: 11,
      startVerseNumber: 6,
      startSurahNameEn: 'Hud',
      startSurahNameAr: 'هود',
    ),
    JuzInfo(
      juzNumber: 13,
      startSurahId: 12,
      startVerseNumber: 53,
      startSurahNameEn: 'Yusuf',
      startSurahNameAr: 'يوسف',
    ),
    JuzInfo(
      juzNumber: 14,
      startSurahId: 15,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Hijr',
      startSurahNameAr: 'الحجر',
    ),
    JuzInfo(
      juzNumber: 15,
      startSurahId: 17,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Isra',
      startSurahNameAr: 'الإسراء',
    ),
    JuzInfo(
      juzNumber: 16,
      startSurahId: 18,
      startVerseNumber: 75,
      startSurahNameEn: 'Al-Kahf',
      startSurahNameAr: 'الكهف',
    ),
    JuzInfo(
      juzNumber: 17,
      startSurahId: 21,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Anbiya',
      startSurahNameAr: 'الأنبياء',
    ),
    JuzInfo(
      juzNumber: 18,
      startSurahId: 23,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Mu\'minun',
      startSurahNameAr: 'المؤمنون',
    ),
    JuzInfo(
      juzNumber: 19,
      startSurahId: 25,
      startVerseNumber: 21,
      startSurahNameEn: 'Al-Furqan',
      startSurahNameAr: 'الفرقان',
    ),
    JuzInfo(
      juzNumber: 20,
      startSurahId: 27,
      startVerseNumber: 56,
      startSurahNameEn: 'An-Naml',
      startSurahNameAr: 'النمل',
    ),
    JuzInfo(
      juzNumber: 21,
      startSurahId: 29,
      startVerseNumber: 46,
      startSurahNameEn: 'Al-Ankabut',
      startSurahNameAr: 'العنكبوت',
    ),
    JuzInfo(
      juzNumber: 22,
      startSurahId: 33,
      startVerseNumber: 31,
      startSurahNameEn: 'Al-Ahzab',
      startSurahNameAr: 'الأحزاب',
    ),
    JuzInfo(
      juzNumber: 23,
      startSurahId: 36,
      startVerseNumber: 28,
      startSurahNameEn: 'Ya-Sin',
      startSurahNameAr: 'يس',
    ),
    JuzInfo(
      juzNumber: 24,
      startSurahId: 39,
      startVerseNumber: 32,
      startSurahNameEn: 'Az-Zumar',
      startSurahNameAr: 'الزمر',
    ),
    JuzInfo(
      juzNumber: 25,
      startSurahId: 41,
      startVerseNumber: 47,
      startSurahNameEn: 'Fussilat',
      startSurahNameAr: 'فصلت',
    ),
    JuzInfo(
      juzNumber: 26,
      startSurahId: 46,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Ahqaf',
      startSurahNameAr: 'الأحقاف',
    ),
    JuzInfo(
      juzNumber: 27,
      startSurahId: 51,
      startVerseNumber: 31,
      startSurahNameEn: 'Adh-Dhariyat',
      startSurahNameAr: 'الذاريات',
    ),
    JuzInfo(
      juzNumber: 28,
      startSurahId: 58,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Mujadila',
      startSurahNameAr: 'المجادلة',
    ),
    JuzInfo(
      juzNumber: 29,
      startSurahId: 67,
      startVerseNumber: 1,
      startSurahNameEn: 'Al-Mulk',
      startSurahNameAr: 'الملك',
    ),
    JuzInfo(
      juzNumber: 30,
      startSurahId: 78,
      startVerseNumber: 1,
      startSurahNameEn: 'An-Naba',
      startSurahNameAr: 'النبأ',
    ),
  ];

  /// Get Juz info by number (1-30)
  static JuzInfo? getJuz(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) return null;
    return allJuz[juzNumber - 1];
  }

  /// Get localized Juz name
  static String getJuzName(int juzNumber, {required bool isArabic}) {
    if (isArabic) {
      return 'الجزء $juzNumber';
    }
    return 'Juz $juzNumber';
  }
}

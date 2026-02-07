/// Mushaf Page Index - Maps Madani Mushaf pages (1-604) to Surahs and Verses
/// Based on the standard Madani Mushaf (Uthmani script) pagination
class MushafPageIndex {
  static const int totalPages = 604;
  
  /// Page info containing Surah and verse range
  final int pageNumber;
  final int surahId;
  final int startVerse;
  final int endVerse;
  final String surahNameAr;
  final String surahNameEn;
  
  const MushafPageIndex({
    required this.pageNumber,
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    required this.surahNameAr,
    required this.surahNameEn,
  });
  
  /// Get all pages data
  static List<MushafPageIndex> getAllPages() {
    return _pagesData.map((data) => MushafPageIndex(
      pageNumber: data[0] as int,
      surahId: data[1] as int,
      startVerse: data[2] as int,
      endVerse: data[3] as int,
      surahNameAr: data[4] as String,
      surahNameEn: data[5] as String,
    )).toList();
  }
  
  /// Get page by page number (1-604)
  static MushafPageIndex? getPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPages) return null;
    final data = _pagesData[pageNumber - 1];
    return MushafPageIndex(
      pageNumber: data[0] as int,
      surahId: data[1] as int,
      startVerse: data[2] as int,
      endVerse: data[3] as int,
      surahNameAr: data[4] as String,
      surahNameEn: data[5] as String,
    );
  }
  
  /// Find page number for a specific verse
  static int? findPageForVerse(int surahId, int verseNumber) {
    for (final page in _pagesData) {
      if (page[1] == surahId && 
          verseNumber >= page[2] && 
          verseNumber <= page[3]) {
        return page[0] as int;
      }
    }
    return null;
  }
  
  /// Get all verses for a specific page
  static List<MushafVerse> getVersesForPage(int pageNumber) {
    final page = getPage(pageNumber);
    if (page == null) return [];
    
    final verses = <MushafVerse>[];
    for (int v = page.startVerse; v <= page.endVerse; v++) {
      verses.add(MushafVerse(
        surahId: page.surahId,
        verseNumber: v,
        pageNumber: pageNumber,
      ));
    }
    return verses;
  }
  
  /// Check if page is the start of a Surah
  bool get isSurahStart => startVerse == 1;
  
  /// Check if page contains Bismillah (first page of Surah, except Surah 1 and 9)
  bool get containsBismillah => isSurahStart && surahId != 1 && surahId != 9;
}

/// Represents a verse within a Mushaf page
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

/// Simplified page data - in production, this would be loaded from a JSON file
/// Format: [pageNumber, surahId, startVerse, endVerse, surahNameAr, surahNameEn]
/// This is a condensed version - full data would have all 604 pages
final List<List<dynamic>> _pagesData = [
  // Page 1: Al-Fatiha 1-7
  [1, 1, 1, 7, "الفاتحة", "Al-Fatiha"],
  // Page 2: Al-Baqarah 1-5
  [2, 2, 1, 5, "البقرة", "Al-Baqarah"],
  // Pages 3-49: Al-Baqarah (simplified - would be full data)
  [3, 2, 6, 16, "البقرة", "Al-Baqarah"],
  [4, 2, 17, 24, "البقرة", "Al-Baqarah"],
  [5, 2, 25, 29, "البقرة", "Al-Baqarah"],
  // ... This would continue for all 604 pages
  // For now, using generated placeholder data for remaining pages
  ..._generateRemainingPages(),
];

/// Generate placeholder data for remaining pages
/// In production, replace with actual Mushaf page mappings
List<List<dynamic>> _generateRemainingPages() {
  final pages = <List<dynamic>>[];
  
  // Surah verse counts for generating approximate pages
  final surahVerses = [
    [2, 286], [3, 200], [4, 176], [5, 120], [6, 165], [7, 206], [8, 75],
    [9, 129], [10, 109], [11, 123], [12, 111], [13, 43], [14, 52], [15, 99],
    [16, 128], [17, 111], [18, 110], [19, 98], [20, 135], [21, 112], [22, 78],
    [23, 118], [24, 64], [25, 77], [26, 227], [27, 93], [28, 88], [29, 69],
    [30, 60], [31, 34], [32, 30], [33, 73], [34, 54], [35, 45], [36, 83],
    [37, 182], [38, 88], [39, 75], [40, 85], [41, 54], [42, 53], [43, 89],
    [44, 59], [45, 37], [46, 35], [47, 38], [48, 29], [49, 18], [50, 45],
    [51, 60], [52, 49], [53, 62], [54, 55], [55, 78], [56, 96], [57, 29],
    [58, 22], [59, 24], [60, 13], [61, 14], [62, 11], [63, 11], [64, 18],
    [65, 12], [66, 12], [67, 30], [68, 52], [69, 52], [70, 44], [71, 28],
    [72, 28], [73, 20], [74, 56], [75, 40], [76, 31], [77, 50], [78, 40],
    [79, 46], [80, 42], [81, 29], [82, 19], [83, 36], [84, 25], [85, 22],
    [86, 17], [87, 19], [88, 26], [89, 30], [90, 20], [91, 15], [92, 21],
    [93, 11], [94, 8], [95, 8], [96, 19], [97, 5], [98, 8], [99, 8],
    [100, 11], [101, 11], [102, 8], [103, 3], [104, 9], [105, 5], [106, 4],
    [107, 7], [108, 3], [109, 6], [110, 3], [111, 5], [112, 4], [113, 5],
    [114, 6],
  ];
  
  int currentPage = 6;
  for (final surahData in surahVerses) {
    final surahId = surahData[0] as int;
    final verseCount = surahData[1] as int;
    final surahNameAr = _getSurahNameAr(surahId);
    final surahNameEn = _getSurahNameEn(surahId);
    
    // Approximate 10 verses per page (varies in actual Mushaf)
    int versesPerPage = surahId <= 2 ? 6 : (surahId <= 10 ? 8 : 10);
    if (verseCount <= 20) versesPerPage = verseCount;
    
    int currentVerse = 1;
    while (currentVerse <= verseCount) {
      final endVerse = (currentVerse + versesPerPage - 1).clamp(currentVerse, verseCount);
      pages.add([currentPage, surahId, currentVerse, endVerse, surahNameAr, surahNameEn]);
      currentVerse = endVerse + 1;
      currentPage++;
    }
  }
  
  // Ensure we have exactly 604 pages (adjust last entries if needed)
  while (pages.length < 599) {
    pages.add([currentPage, 114, 1, 6, "الناس", "An-Nas"]);
    currentPage++;
  }
  
  return pages;
}

String _getSurahNameAr(int surahId) {
  final names = [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف",
    "الأنفال", "التوبة", "يونس", "هود", "يوسف", "الرعد", "إبراهيم", "الحجر",
    "النحل", "الإسراء", "الكهف", "مريم", "طه", "الأنبياء", "الحج", "المؤمنون",
    "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص",
    "الزمر", "غافر", "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية",
    "الأحقاف", "محمد", "الفتح", "الحجرات", "ق", "الذاريات", "الطور",
    "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر",
    "الممتحنة", "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم",
    "الملك", "القلم", "الحاقة", "المعارج", "نوح", "الجن", "المزمل", "المدثر",
    "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس", "التكوير",
    "الإنفطار", "المطففين", "الإنشقاق", "البروج", "الطارق", "الأعلى",
    "الغاشية", "الفجر", "البلد", "الشمس", "الليل", "الضحى", "الشرح",
    "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات", "القارعة",
    "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر",
    "الكافرون", "النصر", "المسد", "الإخلاص", "الفلق", "الناس"
  ];
  return names[surahId - 1];
}

String _getSurahNameEn(int surahId) {
  final names = [
    "Al-Fatiha", "Al-Baqarah", "Aal-E-Imran", "An-Nisa", "Al-Ma'idah",
    "Al-An'am", "Al-A'raf", "Al-Anfal", "At-Tawbah", "Yunus", "Hud",
    "Yusuf", "Ar-Ra'd", "Ibrahim", "Al-Hijr", "An-Nahl", "Al-Isra",
    "Al-Kahf", "Maryam", "Taha", "Al-Anbiya", "Al-Hajj", "Al-Mu'minun",
    "An-Nur", "Al-Furqan", "Ash-Shu'ara", "An-Naml", "Al-Qasas",
    "Al-Ankabut", "Ar-Rum", "Luqman", "As-Sajda", "Al-Ahzab", "Saba",
    "Fatir", "Ya-Sin", "As-Saffat", "Sad", "Az-Zumar", "Ghafir",
    "Fussilat", "Ash-Shura", "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiya",
    "Al-Ahqaf", "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf", "Adh-Dhariyat",
    "At-Tur", "An-Najm", "Al-Qamar", "Ar-Rahman", "Al-Waqi'a", "Al-Hadid",
    "Al-Mujadila", "Al-Hashr", "Al-Mumtahanah", "As-Saff", "Al-Jumu'a",
    "Al-Munafiqun", "At-Taghabun", "At-Talaq", "At-Tahrim", "Al-Mulk",
    "Al-Qalam", "Al-Haqqah", "Al-Ma'arij", "Nuh", "Al-Jinn", "Al-Muzzammil",
    "Al-Muddaththir", "Al-Qiyamah", "Al-Insan", "Al-Mursalat", "An-Naba",
    "An-Nazi'at", "Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin",
    "Al-Inshiqaq", "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghashiyah",
    "Al-Fajr", "Al-Balad", "Ash-Shams", "Al-Layl", "Ad-Duha", "Ash-Sharh",
    "At-Tin", "Al-Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zilzal", "Al-Adiyat",
    "Al-Qari'a", "At-Takathur", "Al-Asr", "Al-Humazah", "Al-Fil",
    "Quraysh", "Al-Ma'un", "Al-Kawthar", "Al-Kafirun", "An-Nasr",
    "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas"
  ];
  return names[surahId - 1];
}

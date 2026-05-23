import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';

enum MushafType {
  madani,
  naskh,
  warsh,
  shemerly;

  /// Quran Foundation API mushaf ID.
  /// See https://api-docs.quran.com/docs/category/mushaf
  int get qfMushafId => switch (this) {
    MushafType.madani => 1,
    MushafType.naskh => 3,
    MushafType.warsh => 2,
    MushafType.shemerly => 1,
  };

  int get totalPages => switch (this) {
    MushafType.madani => 604,
    MushafType.warsh => 604,
    MushafType.naskh => 612,
    MushafType.shemerly => 521,
  };

  // ─── Per-type Juz start pages ───────────────────────────────────

  static const List<int> _madaniJuzPages = [
    1, 21, 42, 62, 82, 106, 127, 151, 177, 187,
    208, 224, 249, 255, 266, 282, 293, 305, 322, 342,
    360, 382, 399, 414, 426, 440, 452, 468, 486, 516,
  ];

  static const List<int> _naskhJuzPages = [
    1, 21, 43, 63, 83, 107, 129, 153, 179, 189,
    211, 227, 252, 258, 269, 286, 297, 309, 326, 346,
    364, 387, 404, 419, 431, 445, 458, 474, 492, 523,
  ];

  static const List<int> _shemerlyJuzPages = [
    1, 18, 36, 53, 71, 91, 110, 130, 153, 161,
    179, 193, 215, 220, 229, 243, 253, 263, 278, 295,
    311, 330, 344, 357, 367, 380, 390, 404, 419, 445,
  ];

  List<int> get juzStartPages => switch (this) {
    MushafType.madani || MushafType.warsh => _madaniJuzPages,
    MushafType.naskh => _naskhJuzPages,
    MushafType.shemerly => _shemerlyJuzPages,
  };

  /// Returns the first page of [juz] (1–30) for this Mushaf type.
  int getJuzPage(int juz) {
    if (juz < 1 || juz > 30) return 1;
    return juzStartPages[juz - 1];
  }

  /// Returns which Juz (1–30) contains [page] for this Mushaf type.
  int getJuzForPage(int page) {
    if (page < 1 || page > totalPages) return 1;
    final pages = juzStartPages;
    for (int i = pages.length - 1; i >= 0; i--) {
      if (pages[i] <= page) return i + 1;
    }
    return 1;
  }

  /// Returns the start page of [surahId] (1–114) for this Mushaf type.
  int getSurahStartPage(int surahId) {
    if (surahId < 1 || surahId > 114) return 1;
    final madaniPage = MushafPageIndex.getPageForSurah(surahId);
    if (totalPages == MushafPageIndex.totalPages) return madaniPage;
    return (madaniPage / MushafPageIndex.totalPages * totalPages)
        .round()
        .clamp(1, totalPages);
  }

  String get baseUrl => switch (this) {
    MushafType.madani => 'https://android.quran.com/data/width_1280/page',
    MushafType.naskh => 'https://files.quran.app/hafs/naskh/width_1280/page',
    MushafType.warsh =>
      'https://files.quran.app/warsh/original/width_1024/page',
    MushafType.shemerly =>
      'https://files.quran.app/hafs/shemerly/width_1200/page',
  };

  /// Selects the closest CDN width for the given [devicePixelRatio].
  /// - ≤2.0  → 640  (low-end phones)
  /// - ≤2.5  → 1024 (default / most phones)
  /// - >2.5  → 1280 (tablets / high-DPI devices)
  String _baseUrlForPixelRatio(double devicePixelRatio) {
    final targetWidth = switch (devicePixelRatio) {
      <= 2.0 => 640,
      <= 2.5 => 1024,
      _ => 1280,
    };
    return baseUrl.replaceFirst(RegExp(r'width_\d+'), 'width_$targetWidth');
  }

  String get label => switch (this) {
    MushafType.madani => 'lbl_mushaf_madani',
    MushafType.naskh => 'lbl_mushaf_naskh',
    MushafType.warsh => 'lbl_mushaf_warsh',
    MushafType.shemerly => 'lbl_mushaf_shemerly',
  };

  String get descriptionKey => switch (this) {
    MushafType.madani => 'lbl_mushaf_madani_desc',
    MushafType.naskh => 'lbl_mushaf_naskh_desc',
    MushafType.warsh => 'lbl_mushaf_warsh_desc',
    MushafType.shemerly => 'lbl_mushaf_shemerly_desc',
  };

  /// Color used for the onboarding card.
  int get colorValue => switch (this) {
    MushafType.madani => 0xFF009688, // teal
    MushafType.shemerly => 0xFF2196F3, // blue
    MushafType.naskh => 0xFFFF9800, // orange
    MushafType.warsh => 0xFF9C27B0, // purple
  };

  String pageImageUrl(int pageNumber, {double? devicePixelRatio}) {
    final base = devicePixelRatio != null
        ? _baseUrlForPixelRatio(devicePixelRatio)
        : baseUrl;
    final padded = pageNumber.toString().padLeft(3, '0');
    return '$base$padded.png';
  }

  /// Parses a stored preference string into a [MushafType].
  /// Handles legacy values: 'indopak' → naskh, 'egyptian' → shemerly.
  static MushafType fromString(String? value) => switch (value) {
    'madani' => MushafType.madani,
    'naskh' || 'indopak' => MushafType.naskh,
    'warsh' => MushafType.warsh,
    'shemerly' || 'egyptian' => MushafType.shemerly,
    _ => MushafType.madani,
  };

  static const List<MushafType> all = MushafType.values;
}

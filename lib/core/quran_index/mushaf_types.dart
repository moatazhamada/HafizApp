enum MushafType {
  madani,
  naskh,
  warsh,
  shemerly;

  int get totalPages => switch (this) {
    MushafType.madani => 604,
    MushafType.warsh => 604,
    MushafType.naskh => 612,
    MushafType.shemerly => 521,
  };

  String get baseUrl => switch (this) {
    MushafType.madani => 'https://android.quran.com/data/width_1280/page',
    MushafType.naskh => 'https://files.quran.app/hafs/naskh/width_1280/page',
    MushafType.warsh =>
      'https://files.quran.app/warsh/original/width_1024/page',
    MushafType.shemerly =>
      'https://files.quran.app/hafs/shemerly/width_1200/page',
  };

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

  String pageImageUrl(int pageNumber) {
    final padded = pageNumber.toString().padLeft(3, '0');
    return '$baseUrl$padded.png';
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

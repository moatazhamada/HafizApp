class VerseText {
  final int surahId;
  final int verseNumber;
  final String text;
  final String surahNameArabic;
  final bool showBismillah;

  const VerseText({
    required this.surahId,
    required this.verseNumber,
    required this.text,
    required this.surahNameArabic,
    required this.showBismillah,
  });
}

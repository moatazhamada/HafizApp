class Bookmark {
  final int surahId;
  final int verse;
  final String text;
  final String surahName;

  Bookmark(
      {required this.surahId,
      required this.verse,
      required this.text,
      required this.surahName});

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'verse': verse,
      'text': text,
      'surahName': surahName
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
        surahId: json['surahId'],
        verse: json['verse'],
        text: json['text'],
        surahName: json['surahName']);
  }
}

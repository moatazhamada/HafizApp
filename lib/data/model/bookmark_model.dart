class BookmarkModel {
  final int surahId;
  final String surahName;
  final int verseId;
  final DateTime createdAt;

  BookmarkModel({
    required this.surahId,
    required this.surahName,
    required this.verseId,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String,
      verseId: json['verseId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'surahName': surahName,
      'verseId': verseId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

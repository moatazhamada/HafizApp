import '../../domain/entities/bookmark.dart';

class BookmarkModel extends Bookmark {
  const BookmarkModel({
    required super.surahId,
    required super.surahName,
    required super.verseNumber,
    required super.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawVerse = json['verseNumber'] ?? json['verseId'] ?? json['verse'];
    final verseNum = rawVerse is int
        ? rawVerse
        : (int.tryParse(rawVerse.toString()) ?? 1);

    final dynamic rawSurahId = json['surahId'];
    final surahId = rawSurahId is int
        ? rawSurahId
        : (int.tryParse(rawSurahId.toString()) ?? 1);

    final dynamic rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? (DateTime.tryParse(rawCreatedAt) ?? DateTime.now())
        : DateTime.now();

    return BookmarkModel(
      surahId: surahId,
      surahName: json['surahName']?.toString() ?? '',
      verseNumber: verseNum,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'surahName': surahName,
      'verseNumber': verseNumber,
      // Keep for backward compatibility if older builds expect it:
      'verseId': verseNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromEntity(Bookmark bookmark) {
    return BookmarkModel(
      surahId: bookmark.surahId,
      surahName: bookmark.surahName,
      verseNumber: bookmark.verseNumber,
      createdAt: bookmark.createdAt,
    );
  }
}

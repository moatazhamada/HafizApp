import '../../domain/entities/bookmark.dart';

class BookmarkModel extends Bookmark {
  const BookmarkModel({
    required super.surahId,
    required super.surahName,
    required super.verseNumber,
    required super.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    final verseNum = (json['verseNumber'] ??
            json['verseId'] ??
            json['verse']) as int;

    return BookmarkModel(
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String,
      verseNumber: verseNum,
      createdAt: DateTime.parse(json['createdAt'] as String),
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

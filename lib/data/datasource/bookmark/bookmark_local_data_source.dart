import 'package:hive_flutter/hive_flutter.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import '../../model/bookmark_model.dart';

abstract class BookmarkLocalDataSource {
  Future<List<BookmarkModel>> getBookmarks();
  Future<bool> addBookmark(BookmarkModel bookmark);
  Future<bool> removeBookmark(int surahId, int verseNumber);
  Future<bool> isBookmarked(int surahId, int verseNumber);
  Future<bool> clearAll();
}

class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  final Box box;

  BookmarkLocalDataSourceImpl({Box? box}) : box = box ?? Hive.box('bookmarks');

  @override
  Future<List<BookmarkModel>> getBookmarks() async {
    final List<dynamic> raw = box.values.toList();
    final List<BookmarkModel> bookmarks = [];

    for (final e in raw) {
      if (e is! Map) continue;
      try {
        bookmarks.add(BookmarkModel.fromJson(Map<String, dynamic>.from(e)));
      } catch (e) {
        // Skip malformed entries instead of failing the entire read.
        Logger.warning('Skipping malformed bookmark entry: $e', feature: 'BookmarkLocal');
        continue;
      }
    }

    return bookmarks;
  }

  @override
  Future<bool> addBookmark(BookmarkModel bookmark) async {
    final key = '${bookmark.surahId}_${bookmark.verseNumber}';
    // Preserve the original creation timestamp if this bookmark already exists
    // so duplicate adds don't reset the date.
    if (box.containsKey(key)) {
      final existing = box.get(key);
      if (existing is Map) {
        final existingCreatedAt = existing['createdAt'];
        if (existingCreatedAt != null) {
          final updated = BookmarkModel(
            surahId: bookmark.surahId,
            surahName: bookmark.surahName,
            verseNumber: bookmark.verseNumber,
            createdAt: DateTime.tryParse(existingCreatedAt.toString()) ??
                bookmark.createdAt,
          );
          await box.put(key, updated.toJson());
          return true;
        }
      }
    }
    await box.put(key, bookmark.toJson());
    return true;
  }

  @override
  Future<bool> removeBookmark(int surahId, int verseNumber) async {
    final key = '${surahId}_$verseNumber';
    await box.delete(key);
    return true;
  }

  @override
  Future<bool> isBookmarked(int surahId, int verseNumber) async {
    final key = '${surahId}_$verseNumber';
    return box.containsKey(key);
  }

  @override
  Future<bool> clearAll() async {
    await box.clear();
    return true;
  }
}

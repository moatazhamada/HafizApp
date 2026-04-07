import 'package:hive_flutter/hive_flutter.dart';
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
      } catch (_) {
        // Skip malformed entries instead of failing the entire read.
        continue;
      }
    }

    return bookmarks;
  }

  @override
  Future<bool> addBookmark(BookmarkModel bookmark) async {
    final key = '${bookmark.surahId}_${bookmark.verseNumber}';
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

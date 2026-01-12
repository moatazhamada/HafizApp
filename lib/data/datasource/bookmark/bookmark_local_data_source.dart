import 'package:hive_flutter/hive_flutter.dart';
import '../../model/bookmark_model.dart';

abstract class BookmarkLocalDataSource {
  Future<List<BookmarkModel>> getBookmarks();
  Future<bool> addBookmark(BookmarkModel bookmark);
  Future<bool> removeBookmark(int surahId, int verseId);
  Future<bool> isBookmarked(int surahId, int verseId);
}

class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  final Box box;

  BookmarkLocalDataSourceImpl({Box? box}) : box = box ?? Hive.box('bookmarks');

  @override
  Future<List<BookmarkModel>> getBookmarks() async {
    final List<dynamic> raw = box.values.toList();
    return raw
        .map((e) => BookmarkModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<bool> addBookmark(BookmarkModel bookmark) async {
    final key = '${bookmark.surahId}_${bookmark.verseId}';
    await box.put(key, bookmark.toJson());
    return true;
  }

  @override
  Future<bool> removeBookmark(int surahId, int verseId) async {
    final key = '${surahId}_${verseId}';
    await box.delete(key);
    return true;
  }

  @override
  Future<bool> isBookmarked(int surahId, int verseId) async {
    final key = '${surahId}_${verseId}';
    return box.containsKey(key);
  }
}

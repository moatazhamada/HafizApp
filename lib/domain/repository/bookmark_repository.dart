import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<Either<Failure, List<Bookmark>>> getBookmarks();
  Future<Either<Failure, bool>> addBookmark(Bookmark bookmark);
  Future<Either<Failure, bool>> removeBookmark(int surahId, int verseNumber);
  Future<Either<Failure, bool>> isBookmarked(int surahId, int verseNumber);
}

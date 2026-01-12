import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/model/bookmark_model.dart';

abstract class BookmarkRepository {
  Future<Either<Failure, List<BookmarkModel>>> getBookmarks();
  Future<Either<Failure, bool>> addBookmark(BookmarkModel bookmark);
  Future<Either<Failure, bool>> removeBookmark(int surahId, int verseId);
  Future<Either<Failure, bool>> isBookmarked(int surahId, int verseId);
}

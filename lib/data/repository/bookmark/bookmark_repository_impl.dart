import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../model/bookmark_model.dart';
import '../../datasource/bookmark/bookmark_local_data_source.dart';
import '../../../domain/repository/bookmark_repository.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource localDataSource;

  BookmarkRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<BookmarkModel>>> getBookmarks() async {
    try {
      final result = await localDataSource.getBookmarks();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure("Failed to load bookmarks"));
    }
  }

  @override
  Future<Either<Failure, bool>> addBookmark(BookmarkModel bookmark) async {
    try {
      final result = await localDataSource.addBookmark(bookmark);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure("Failed to add bookmark"));
    }
  }

  @override
  Future<Either<Failure, bool>> removeBookmark(int surahId, int verseId) async {
    try {
      final result = await localDataSource.removeBookmark(surahId, verseId);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure("Failed to remove bookmark"));
    }
  }

  @override
  Future<Either<Failure, bool>> isBookmarked(int surahId, int verseId) async {
    try {
      final result = await localDataSource.isBookmarked(surahId, verseId);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure("Failed to check bookmark status"));
    }
  }
}

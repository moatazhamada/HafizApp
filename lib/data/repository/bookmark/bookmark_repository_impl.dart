import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../model/bookmark_model.dart';
import '../../datasource/bookmark/bookmark_local_data_source.dart';
import '../../../domain/repository/bookmark_repository.dart';

import '../../../domain/entities/bookmark.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource localDataSource;

  BookmarkRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Bookmark>>> getBookmarks() async {
    try {
      final result = await localDataSource.getBookmarks();
      return Right(result);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to load bookmarks: $e',
        feature: 'Bookmarks',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to load bookmarks'));
    }
  }

  @override
  Future<Either<Failure, bool>> addBookmark(Bookmark bookmark) async {
    try {
      final model = BookmarkModel.fromEntity(bookmark);
      final result = await localDataSource.addBookmark(model);
      return Right(result);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to add bookmark: $e',
        feature: 'Bookmarks',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to add bookmark'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeBookmark(
    int surahId,
    int verseNumber,
  ) async {
    try {
      final result = await localDataSource.removeBookmark(surahId, verseNumber);
      return Right(result);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to remove bookmark: $e',
        feature: 'Bookmarks',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to remove bookmark'));
    }
  }

  @override
  Future<Either<Failure, bool>> isBookmarked(
    int surahId,
    int verseNumber,
  ) async {
    try {
      final result = await localDataSource.isBookmarked(surahId, verseNumber);
      return Right(result);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to check bookmark status: $e',
        feature: 'Bookmarks',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(CacheFailure('Failed to check bookmark status'));
    }
  }
}
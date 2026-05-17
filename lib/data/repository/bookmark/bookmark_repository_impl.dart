import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/errors/failures.dart';
import '../../../core/quran_index/mushaf_page_index.dart';
import '../../../core/utils/logger.dart';
import '../../../injection_container.dart';
import '../../datasource/qf_user_api_remote_data_source.dart';
import '../../model/bookmark_model.dart';
import '../../datasource/bookmark/bookmark_local_data_source.dart';
import '../../../domain/repository/bookmark_repository.dart';

import '../../../domain/entities/bookmark.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource localDataSource;
  final QfUserApiRemoteDataSource? remoteDataSource;

  BookmarkRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

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

      unawaited(sl<AnalyticsService>().logBookmarkAdded(
        surahId: bookmark.surahId,
        verseNumber: bookmark.verseNumber,
      ));

      // Fire-and-forget: sync to QF if authenticated
      unawaited(_syncAddToRemote(bookmark));

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

      unawaited(sl<AnalyticsService>().logBookmarkRemoved(
        surahId: surahId,
        verseNumber: verseNumber,
      ));

      // Fire-and-forget: sync to QF if authenticated
      unawaited(_syncRemoveToRemote(surahId, verseNumber));

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

  Future<void> _syncAddToRemote(Bookmark bookmark) async {
    if (remoteDataSource == null) return;
    try {
      final verseId = _toAbsoluteVerseId(bookmark.surahId, bookmark.verseNumber);
      await remoteDataSource!.addBookmark(verseId);
      Logger.info(
        'Synced bookmark ${bookmark.surahId}:${bookmark.verseNumber} to QF',
        feature: 'Bookmarks',
      );
    } catch (e) {
      Logger.warning(
        'Failed to sync bookmark add to QF: $e',
        feature: 'Bookmarks',
      );
    }
  }

  Future<void> _syncRemoveToRemote(int surahId, int verseNumber) async {
    if (remoteDataSource == null) return;
    try {
      final verseId = _toAbsoluteVerseId(surahId, verseNumber);
      await remoteDataSource!.removeBookmark(verseId);
      Logger.info(
        'Synced bookmark removal $surahId:$verseNumber to QF',
        feature: 'Bookmarks',
      );
    } catch (e) {
      Logger.warning(
        'Failed to sync bookmark removal to QF: $e',
        feature: 'Bookmarks',
      );
    }
  }

  int _toAbsoluteVerseId(int surahId, int verseNumber) {
    return MushafPageIndex.getAbsoluteVerseId(surahId, verseNumber);
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
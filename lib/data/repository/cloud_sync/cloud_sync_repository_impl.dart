import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/bookmark/bookmark_local_data_source.dart';
import 'package:hafiz_app/data/datasource/cloud_sync/cloud_sync_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/recitation_error/recitation_error_local_data_source.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/data/model/sync/sync_user_settings_model.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  final CloudSyncRemoteDataSource remoteDataSource;
  final BookmarkLocalDataSource bookmarkLocalDataSource;
  final RecitationErrorLocalDataSource recitationErrorLocalDataSource;

  CloudSyncRepositoryImpl({
    required this.remoteDataSource,
    required this.bookmarkLocalDataSource,
    required this.recitationErrorLocalDataSource,
  });

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final result = await remoteDataSource.isAuthenticated();
      return Right(result);
    } catch (e) {
      Logger.error('Failed to check auth: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to check authentication'));
    }
  }

  @override
  Future<Either<Failure, String?>> getCurrentUserId() async {
    try {
      final result = await remoteDataSource.getCurrentUserId();
      return Right(result);
    } catch (e) {
      Logger.error('Failed to get user ID: $e', feature: 'CloudSync');
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> signInAnonymously() async {
    try {
      await remoteDataSource.signInAnonymously();
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to sign in: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to sign in anonymously'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to sign out: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to sign out'));
    }
  }

  @override
  Future<Either<Failure, SyncUserSettingsModel?>> getRemoteSettings(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getUserSettings(userId);
      return Right(result);
    } catch (e) {
      Logger.error('Failed to get remote settings: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to get remote settings'));
    }
  }

  @override
  Future<Either<Failure, void>> syncSettings(
    String userId,
    SyncUserSettingsModel settings,
  ) async {
    try {
      await remoteDataSource.saveUserSettings(userId, settings);
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to sync settings: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to sync settings'));
    }
  }

  @override
  Future<Either<Failure, List<BookmarkModel>>> getRemoteBookmarks(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getBookmarks(userId);
      return Right(result);
    } catch (e) {
      Logger.error('Failed to get remote bookmarks: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to get remote bookmarks'));
    }
  }

  @override
  Future<Either<Failure, void>> syncBookmarks(
    String userId,
    List<BookmarkModel> bookmarks,
  ) async {
    try {
      await remoteDataSource.saveBookmarks(userId, bookmarks);
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to sync bookmarks: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to sync bookmarks'));
    }
  }

  @override
  Future<Either<Failure, List<RecitationErrorModel>>> getRemoteRecitationErrors(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getRecitationErrors(userId);
      return Right(result);
    } catch (e) {
      Logger.error('Failed to get remote errors: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to get remote recitation errors'));
    }
  }

  @override
  Future<Either<Failure, void>> syncRecitationErrors(
    String userId,
    List<RecitationErrorModel> errors,
  ) async {
    try {
      await remoteDataSource.saveRecitationErrors(userId, errors);
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to sync errors: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to sync recitation errors'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime(String userId) async {
    try {
      final result = await remoteDataSource.getLastSyncTime(userId);
      return Right(result);
    } catch (e) {
      Logger.error('Failed to get last sync time: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to get last sync time'));
    }
  }

  @override
  Future<Either<Failure, void>> setLastSyncTime(
    String userId,
    DateTime time,
  ) async {
    try {
      await remoteDataSource.setLastSyncTime(userId, time);
      return const Right(null);
    } catch (e) {
      Logger.error('Failed to set last sync time: $e', feature: 'CloudSync');
      return Left(ServerFailure('Failed to set last sync time'));
    }
  }

  @override
  Future<Either<Failure, void>> performFullSync(
    String userId, {
    required SyncDirection direction,
  }) async {
    try {
      final now = DateTime.now();

      switch (direction) {
        case SyncDirection.localToRemote:
          final localBookmarks = await bookmarkLocalDataSource.getBookmarks();
          await remoteDataSource.saveBookmarks(userId, localBookmarks);
          Logger.info(
            'Synced ${localBookmarks.length} bookmarks to remote',
            feature: 'CloudSync',
          );

          final localErrors = await recitationErrorLocalDataSource
              .getRecitationErrors();
          await remoteDataSource.saveRecitationErrors(userId, localErrors);
          Logger.info(
            'Synced ${localErrors.length} recitation errors to remote',
            feature: 'CloudSync',
          );
          break;

        case SyncDirection.remoteToLocal:
          final remoteBookmarks = await remoteDataSource.getBookmarks(userId);
          await bookmarkLocalDataSource.clearAll();
          for (final bookmark in remoteBookmarks) {
            await bookmarkLocalDataSource.addBookmark(bookmark);
          }
          Logger.info(
            'Synced ${remoteBookmarks.length} bookmarks from remote',
            feature: 'CloudSync',
          );

          final remoteErrors = await remoteDataSource.getRecitationErrors(
            userId,
          );
          await recitationErrorLocalDataSource.clearAll();
          for (final error in remoteErrors) {
            await recitationErrorLocalDataSource.addRecitationError(error);
          }
          Logger.info(
            'Synced ${remoteErrors.length} errors from remote',
            feature: 'CloudSync',
          );
          break;

        case SyncDirection.bidirectional:
          final localBookmarks = await bookmarkLocalDataSource.getBookmarks();
          final remoteBookmarks = await remoteDataSource.getBookmarks(userId);

          final mergedBookmarks = _mergeBookmarks(
            localBookmarks,
            remoteBookmarks,
          );
          await remoteDataSource.saveBookmarks(userId, mergedBookmarks);

          await bookmarkLocalDataSource.clearAll();
          for (final bookmark in mergedBookmarks) {
            await bookmarkLocalDataSource.addBookmark(bookmark);
          }
          Logger.info(
            'Merged ${mergedBookmarks.length} bookmarks (bidirectional)',
            feature: 'CloudSync',
          );

          final localErrors = await recitationErrorLocalDataSource
              .getRecitationErrors();
          final cloudErrors = await remoteDataSource.getRecitationErrors(
            userId,
          );

          final mergedErrors = _mergeRecitationErrors(localErrors, cloudErrors);
          await remoteDataSource.saveRecitationErrors(userId, mergedErrors);

          await recitationErrorLocalDataSource.clearAll();
          for (final error in mergedErrors) {
            await recitationErrorLocalDataSource.addRecitationError(error);
          }
          Logger.info(
            'Merged ${mergedErrors.length} errors (bidirectional)',
            feature: 'CloudSync',
          );
          break;
      }

      await remoteDataSource.setLastSyncTime(userId, now);
      return const Right(null);
    } catch (e, stackTrace) {
      Logger.error(
        'Full sync failed: $e',
        feature: 'CloudSync',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Failed to perform full sync'));
    }
  }

  List<BookmarkModel> _mergeBookmarks(
    List<BookmarkModel> local,
    List<BookmarkModel> remote,
  ) {
    final Map<String, BookmarkModel> merged = {};

    for (final b in remote) {
      final key = '${b.surahId}_${b.verseNumber}';
      merged[key] = b;
    }

    for (final b in local) {
      final key = '${b.surahId}_${b.verseNumber}';
      if (!merged.containsKey(key)) {
        merged[key] = b;
      } else {
        final existing = merged[key]!;
        if (b.createdAt.isAfter(existing.createdAt)) {
          merged[key] = b;
        }
      }
    }

    return merged.values.toList();
  }

  List<RecitationErrorModel> _mergeRecitationErrors(
    List<RecitationErrorModel> local,
    List<RecitationErrorModel> remote,
  ) {
    final Map<String, RecitationErrorModel> merged = {};

    for (final e in remote) {
      final key = '${e.surahId}_${e.verseId}';
      merged[key] = e;
    }

    for (final e in local) {
      final key = '${e.surahId}_${e.verseId}';
      if (!merged.containsKey(key)) {
        merged[key] = e;
      } else {
        final existing = merged[key]!;
        merged[key] = RecitationErrorModel(
          surahId: e.surahId,
          surahName: e.surahName,
          verseId: e.verseId,
          createdAt: e.createdAt.isAfter(existing.createdAt)
              ? e.createdAt
              : existing.createdAt,
          count: e.count > existing.count ? e.count : existing.count,
        );
      }
    }

    return merged.values.toList();
  }
}

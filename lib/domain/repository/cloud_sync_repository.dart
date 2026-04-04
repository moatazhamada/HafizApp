import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/data/model/sync/sync_user_settings_model.dart';

enum SyncDirection { localToRemote, remoteToLocal, bidirectional }

abstract class CloudSyncRepository {
  Future<Either<Failure, bool>> isAuthenticated();
  Future<Either<Failure, String?>> getCurrentUserId();
  Future<Either<Failure, void>> signInAnonymously();
  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, SyncUserSettingsModel?>> getRemoteSettings(
    String userId,
  );
  Future<Either<Failure, void>> syncSettings(
    String userId,
    SyncUserSettingsModel settings,
  );

  Future<Either<Failure, List<BookmarkModel>>> getRemoteBookmarks(
    String userId,
  );
  Future<Either<Failure, void>> syncBookmarks(
    String userId,
    List<BookmarkModel> bookmarks,
  );

  Future<Either<Failure, List<RecitationErrorModel>>> getRemoteRecitationErrors(
    String userId,
  );
  Future<Either<Failure, void>> syncRecitationErrors(
    String userId,
    List<RecitationErrorModel> errors,
  );

  Future<Either<Failure, DateTime?>> getLastSyncTime(String userId);
  Future<Either<Failure, void>> setLastSyncTime(String userId, DateTime time);

  Future<Either<Failure, void>> performFullSync(
    String userId, {
    required SyncDirection direction,
  });
}

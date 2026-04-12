import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/data/model/sync/sync_user_settings_model.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class CloudSyncRemoteDataSource {
  Future<String?> getCurrentUserId();
  Future<bool> isAuthenticated();
  Future<void> signInAnonymously();
  Future<void> signOut();

  Future<SyncUserSettingsModel?> getUserSettings(String userId);
  Future<void> saveUserSettings(String userId, SyncUserSettingsModel settings);

  Future<List<BookmarkModel>> getBookmarks(String userId);
  Future<void> saveBookmarks(String userId, List<BookmarkModel> bookmarks);
  Future<void> addBookmark(String userId, BookmarkModel bookmark);
  Future<void> removeBookmark(String userId, int surahId, int verseNumber);

  Future<List<RecitationErrorModel>> getRecitationErrors(String userId);
  Future<void> saveRecitationErrors(
    String userId,
    List<RecitationErrorModel> errors,
  );
  Future<void> addRecitationError(String userId, RecitationErrorModel error);
  Future<void> removeRecitationError(String userId, int surahId, int verseId);

  Future<DateTime?> getLastSyncTime(String userId);
  Future<void> setLastSyncTime(String userId, DateTime time);
}

class CloudSyncRemoteDataSourceImpl implements CloudSyncRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudSyncRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  DocumentReference _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  DocumentReference _settingsDoc(String userId) =>
      _userDoc(userId).collection('settings').doc('main');

  CollectionReference _bookmarksCollection(String userId) =>
      _userDoc(userId).collection('bookmarks');

  CollectionReference _errorsCollection(String userId) =>
      _userDoc(userId).collection('recitation_errors');

  @override
  Future<String?> getCurrentUserId() async {
    final user = _auth.currentUser;
    return user?.uid;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        Logger.info('Signed in anonymously', feature: 'CloudSync');
      }
    } catch (e) {
      Logger.error('Failed to sign in anonymously: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.info('Signed out', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to sign out: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<SyncUserSettingsModel?> getUserSettings(String userId) async {
    try {
      final doc = await _settingsDoc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data();
      if (data is! Map<String, dynamic>) return null;
      return SyncUserSettingsModel.fromJson(data);
    } catch (e) {
      Logger.error('Failed to get user settings: $e', feature: 'CloudSync');
      return null;
    }
  }

  @override
  Future<void> saveUserSettings(
    String userId,
    SyncUserSettingsModel settings,
  ) async {
    try {
      await _settingsDoc(userId).set(settings.toJson());
      Logger.info('Saved user settings', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to save user settings: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarks(String userId) async {
    try {
      final snapshot = await _bookmarksCollection(userId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data is! Map<String, dynamic>)
          return BookmarkModel.fromJson(const {});
        return BookmarkModel.fromJson(data);
      }).toList();
    } catch (e) {
      Logger.error('Failed to get bookmarks: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> saveBookmarks(
    String userId,
    List<BookmarkModel> bookmarks,
  ) async {
    try {
      final batch = _firestore.batch();
      final collRef = _bookmarksCollection(userId);

      await collRef.get().then((snapshot) {
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      });

      for (final bookmark in bookmarks) {
        final key = '${bookmark.surahId}_${bookmark.verseNumber}';
        batch.set(collRef.doc(key), bookmark.toJson());
      }

      await batch.commit();
      Logger.info('Saved ${bookmarks.length} bookmarks', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to save bookmarks: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> addBookmark(String userId, BookmarkModel bookmark) async {
    try {
      final key = '${bookmark.surahId}_${bookmark.verseNumber}';
      await _bookmarksCollection(userId).doc(key).set(bookmark.toJson());
      Logger.info('Added bookmark: $key', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to add bookmark: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(
    String userId,
    int surahId,
    int verseNumber,
  ) async {
    try {
      final key = '${surahId}_$verseNumber';
      await _bookmarksCollection(userId).doc(key).delete();
      Logger.info('Removed bookmark: $key', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to remove bookmark: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<List<RecitationErrorModel>> getRecitationErrors(String userId) async {
    try {
      final snapshot = await _errorsCollection(userId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data is! Map<String, dynamic>) {
          return RecitationErrorModel.fromJson(const {});
        }
        return RecitationErrorModel.fromJson(data);
      }).toList();
    } catch (e) {
      Logger.error('Failed to get recitation errors: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> saveRecitationErrors(
    String userId,
    List<RecitationErrorModel> errors,
  ) async {
    try {
      final batch = _firestore.batch();
      final collRef = _errorsCollection(userId);

      await collRef.get().then((snapshot) {
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      });

      for (final error in errors) {
        final key = '${error.surahId}_${error.verseId}';
        batch.set(collRef.doc(key), error.toJson());
      }

      await batch.commit();
      Logger.info(
        'Saved ${errors.length} recitation errors',
        feature: 'CloudSync',
      );
    } catch (e) {
      Logger.error(
        'Failed to save recitation errors: $e',
        feature: 'CloudSync',
      );
      rethrow;
    }
  }

  @override
  Future<void> addRecitationError(
    String userId,
    RecitationErrorModel error,
  ) async {
    try {
      final key = '${error.surahId}_${error.verseId}';
      await _errorsCollection(userId).doc(key).set(error.toJson());
      Logger.info('Added recitation error: $key', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to add recitation error: $e', feature: 'CloudSync');
      rethrow;
    }
  }

  @override
  Future<void> removeRecitationError(
    String userId,
    int surahId,
    int verseId,
  ) async {
    try {
      final key = '${surahId}_$verseId';
      await _errorsCollection(userId).doc(key).delete();
      Logger.info('Removed recitation error: $key', feature: 'CloudSync');
    } catch (e) {
      Logger.error(
        'Failed to remove recitation error: $e',
        feature: 'CloudSync',
      );
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('sync')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final timestamp = doc.data()!['lastSyncTime'] as String?;
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      Logger.error('Failed to get last sync time: $e', feature: 'CloudSync');
      return null;
    }
  }

  @override
  Future<void> setLastSyncTime(String userId, DateTime time) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('sync')
          .set({'lastSyncTime': time.toIso8601String()});
      Logger.info('Saved last sync time', feature: 'CloudSync');
    } catch (e) {
      Logger.error('Failed to set last sync time: $e', feature: 'CloudSync');
      rethrow;
    }
  }
}

import 'dart:convert';

import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class SyncPreferences {
  // ── QF Last Sync ──

  DateTime? getQfLastSyncAt() {
    try {
      final s = PrefUtils.prefs.getString('qf_last_sync_at');
      return s != null ? DateTime.tryParse(s) : null;
    } catch (e) {
      Logger.warning('Failed to read qf_last_sync_at: $e', feature: 'Prefs');
      return null;
    }
  }

  Future<void> setQfLastSyncAt(DateTime dt) async {
    await PrefUtils.prefs.setString('qf_last_sync_at', dt.toIso8601String());
  }

  // ── Bookmark Collection ID ──

  String? getBookmarkCollectionId() {
    try {
      return PrefUtils.prefs.getString('qf_bookmark_collection_id');
    } catch (_) {
      return null;
    }
  }

  Future<void> setBookmarkCollectionId(String id) async {
    await PrefUtils.prefs.setString('qf_bookmark_collection_id', id);
  }

  // ── QF Preference Sync Tracking ──

  static const String _qfPrefSyncPromptedKey = 'qf_pref_sync_prompted';
  static const String _qfPrefSyncDirectionKey = 'qf_pref_sync_direction';

  bool getQfPrefSyncPrompted() {
    try {
      return PrefUtils.prefs.getBool(_qfPrefSyncPromptedKey) ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to read QF pref sync prompted: $e',
        feature: 'Prefs',
      );
      return false;
    }
  }

  Future<void> setQfPrefSyncPrompted(bool value) async {
    await PrefUtils.prefs.setBool(_qfPrefSyncPromptedKey, value);
  }

  String? getQfPrefSyncDirection() {
    try {
      return PrefUtils.prefs.getString(_qfPrefSyncDirectionKey);
    } catch (e) {
      Logger.warning(
        'Failed to read QF pref sync direction: $e',
        feature: 'Prefs',
      );
      return null;
    }
  }

  Future<void> setQfPrefSyncDirection(String? direction) async {
    if (direction == null) {
      await PrefUtils.prefs.remove(_qfPrefSyncDirectionKey);
    } else {
      await PrefUtils.prefs.setString(_qfPrefSyncDirectionKey, direction);
    }
  }

  // ── Recently Deleted Bookmarks (prevents sync pull-back) ──

  static const String _recentlyDeletedBookmarksKey =
      'recently_deleted_bookmarks';

  /// Record a bookmark as recently deleted so cloud sync doesn't pull it back.
  Future<void> recordDeletedBookmark(int surahId, int verseNumber) async {
    try {
      final key = '$surahId:$verseNumber';
      final jsonStr = PrefUtils.prefs.getString(_recentlyDeletedBookmarksKey);
      final Map<String, dynamic> map =
          jsonStr != null ? json.decode(jsonStr) : {};
      map[key] = DateTime.now().toIso8601String();
      // Keep only the last 50 deletions to prevent unbounded growth.
      if (map.length > 50) {
        final sorted = map.entries.toList()
          ..sort((a, b) => DateTime.parse(a.value)
              .compareTo(DateTime.parse(b.value)));
        final toRemove = sorted.take(map.length - 50).map((e) => e.key);
        for (final k in toRemove) {
          map.remove(k);
        }
      }
      await PrefUtils.prefs.setString(
        _recentlyDeletedBookmarksKey,
        json.encode(map),
      );
    } catch (e) {
      Logger.warning('Failed to record deleted bookmark: $e', feature: 'Prefs');
    }
  }

  /// Returns true if this bookmark was deleted locally within the last
  /// [within] duration (default 24 hours).
  bool isRecentlyDeletedBookmark(
    int surahId,
    int verseNumber, {
    Duration within = const Duration(hours: 24),
  }) {
    try {
      final key = '$surahId:$verseNumber';
      final jsonStr = PrefUtils.prefs.getString(_recentlyDeletedBookmarksKey);
      if (jsonStr == null) return false;
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final deletedAtStr = map[key];
      if (deletedAtStr == null) return false;
      final deletedAt = DateTime.tryParse(deletedAtStr.toString());
      if (deletedAt == null) return false;
      return DateTime.now().difference(deletedAt) < within;
    } catch (e) {
      return false;
    }
  }

  /// Clear the recently-deleted tracking (e.g. after a successful sync).
  Future<void> clearRecentlyDeletedBookmarks() async {
    try {
      await PrefUtils.prefs.remove(_recentlyDeletedBookmarksKey);
    } catch (e) {
      Logger.warning(
        'Failed to clear recently deleted bookmarks: $e',
        feature: 'Prefs',
      );
    }
  }
}

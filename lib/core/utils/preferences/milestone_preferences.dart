import 'package:hafiz_app/core/utils/pref_utils.dart';

class MilestonePreferences {
  // ── Goal Celebration ──

  static const String _lastCelebratedDateKey = 'last_celebrated_date';

  String? getLastCelebratedDate() {
    try {
      return PrefUtils.prefs.getString(_lastCelebratedDateKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastCelebratedDate(String date) async {
    await PrefUtils.prefs.setString(_lastCelebratedDateKey, date);
  }

  static const String _lastStreakCelebratedKey = 'last_streak_celebrated';

  int? getLastStreakCelebrated() {
    try {
      return PrefUtils.prefs.getInt(_lastStreakCelebratedKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastStreakCelebrated(int milestone) async {
    await PrefUtils.prefs.setInt(_lastStreakCelebratedKey, milestone);
  }

  // ── Khatmah Completion Tracking ──

  static const String _totalVersesReadKey = 'total_verses_read';
  static const String _khatmahCompletionsKey = 'khatmah_completions';
  static const String _showDuaKhatmKey = 'show_dua_khatm';

  int getTotalVersesRead() {
    try {
      return PrefUtils.prefs.getInt(_totalVersesReadKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> setTotalVersesRead(int value) async {
    await PrefUtils.prefs.setInt(_totalVersesReadKey, value);
  }

  int getKhatmahCompletionsCount() {
    try {
      return PrefUtils.prefs.getInt(_khatmahCompletionsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> setKhatmahCompletionsCount(int value) async {
    await PrefUtils.prefs.setInt(_khatmahCompletionsKey, value);
  }

  bool shouldShowDuaKhatm() {
    try {
      return PrefUtils.prefs.getBool(_showDuaKhatmKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setShouldShowDuaKhatm(bool value) async {
    await PrefUtils.prefs.setBool(_showDuaKhatmKey, value);
  }
}

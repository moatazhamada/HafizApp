import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class NotificationPreferences {
  // ── Daily Verse ──

  bool isDailyVerseEnabled() {
    try {
      return PrefUtils.prefs.getBool('dailyVerseEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> setDailyVerseEnabled(bool enabled) async {
    await PrefUtils.prefs.setBool('dailyVerseEnabled', enabled);
  }

  String getDailyVerseTime() {
    try {
      return PrefUtils.prefs.getString('dailyVerseTime') ?? '08:00';
    } catch (e) {
      return '08:00';
    }
  }

  Future<void> setDailyVerseTime(String time) async {
    await PrefUtils.prefs.setString('dailyVerseTime', time);
  }

  // ── Friday Surah Al-Kahf Reminder ──

  bool isFridayKahfEnabled() {
    try {
      return PrefUtils.prefs.getBool('fridayKahfEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> setFridayKahfEnabled(bool enabled) async {
    await PrefUtils.prefs.setBool('fridayKahfEnabled', enabled);
  }

  String getFridayKahfTime() {
    try {
      return PrefUtils.prefs.getString('fridayKahfTime') ?? '06:00';
    } catch (e) {
      return '06:00';
    }
  }

  Future<void> setFridayKahfTime(String time) async {
    await PrefUtils.prefs.setString('fridayKahfTime', time);
  }

  // ── Reading Reminder ──

  static const String _readingReminderEnabledKey = 'reading_reminder_enabled';

  bool isReadingReminderEnabled() {
    try {
      return PrefUtils.prefs.getBool(_readingReminderEnabledKey) ?? true;
    } catch (e) {
      Logger.warning(
        'Failed to get reading reminder enabled: $e',
        feature: 'Preferences',
      );
      return true;
    }
  }

  Future<void> setReadingReminderEnabled(bool value) async {
    await PrefUtils.prefs.setBool(_readingReminderEnabledKey, value);
  }

  String getReadingReminderTime() {
    try {
      return PrefUtils.prefs.getString('readingReminderTime') ?? '20:00';
    } catch (e) {
      return '20:00';
    }
  }

  Future<void> setReadingReminderTime(String time) async {
    await PrefUtils.prefs.setString('readingReminderTime', time);
  }
}

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

/// Manages all local notifications: daily verse, reading reminders, and streak milestones.
class NotificationService {
  static const String _verseChannelId = 'daily_verse';
  static const String _verseChannelName = 'Daily Verse';
  static const String _verseChannelDescription = 'Daily Quran verse reminder';

  static const String _reminderChannelId = 'reading_reminder';
  static const String _reminderChannelName = 'Reading Reminder';
  static const String _reminderChannelDescription =
      'Gentle reminder to continue your daily reading';

  static const String _streakChannelId = 'streak_milestone';
  static const String _streakChannelName = 'Streak Milestone';
  static const String _streakChannelDescription =
      'Celebrate your reading streak achievements';

  static const int _verseNotificationId = 0;
  static const int _reminderNotificationId = 1;
  static const int _streakNotificationIdBase = 1000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static NotificationService? _instance;

  NotificationService._();

  factory NotificationService() => _instance ??= NotificationService._();

  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Request notification permission on Android 13+ (API 33).
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return true;

      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      Logger.warning(
        'Notification permission request failed: $e',
        feature: 'Notifications',
      );
      return false;
    }
  }

  // ── Daily Verse ──

  Future<void> scheduleDailyVerse() async {
    if (kIsWeb) return;

    final pref = PrefUtils();
    if (!pref.isDailyVerseEnabled()) {
      await _plugin.cancel(_verseNotificationId);
      Logger.info(
        'Daily verse notification cancelled (disabled)',
        feature: 'Notifications',
      );
      return;
    }

    if (!await _ensurePermission()) return;
    await _plugin.cancel(_verseNotificationId);

    final surahs = QuranIndex.quranSurahs;
    final randomSurah = surahs[Random().nextInt(surahs.length)];
    final verseCount = MushafPageIndex.getVerseCount(randomSurah.id);
    final randomVerse = verseCount > 1 ? Random().nextInt(verseCount) + 1 : 1;

    final title = '${randomSurah.nameEnglish} ${randomSurah.nameArabic}';
    final body = 'Verse $randomVerse \u2014 Open Hafiz to read';

    const androidDetails = AndroidNotificationDetails(
      _verseChannelId,
      _verseChannelName,
      channelDescription: _verseChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.periodicallyShow(
      _verseNotificationId,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    Logger.info(
      'Daily verse scheduled: ${randomSurah.nameEnglish} $randomVerse',
      feature: 'Notifications',
    );
  }

  // ── Reading Reminder ──

  Future<void> scheduleReadingReminder() async {
    if (kIsWeb) return;

    final pref = PrefUtils();
    if (!pref.isReadingReminderEnabled()) {
      await _plugin.cancel(_reminderNotificationId);
      Logger.info(
        'Reading reminder cancelled (disabled)',
        feature: 'Notifications',
      );
      return;
    }

    if (!await _ensurePermission()) return;
    await _plugin.cancel(_reminderNotificationId);

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
    );

    await _plugin.periodicallyShow(
      _reminderNotificationId,
      'Time for Quran',
      'Keep your daily reading habit alive \u2014 open Hafiz',
      RepeatInterval.daily,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    Logger.info('Reading reminder scheduled', feature: 'Notifications');
  }

  // ── Streak Milestone (immediate) ──

  /// Show an immediate notification celebrating a streak milestone.
  /// Call this when the app detects a streak achievement.
  Future<void> showStreakMilestone(int streakDays) async {
    if (kIsWeb) return;
    if (!await _ensurePermission()) return;

    final String title;
    final String body;

    if (streakDays == 7) {
      title = '\u2728 One week streak!';
      body = 'You\'ve read Quran for 7 days in a row. Keep it up!';
    } else if (streakDays == 30) {
      title = '\ud83c\udf1f 30-day streak!';
      body = 'Amazing dedication! A full month of daily reading.';
    } else if (streakDays % 10 == 0) {
      title = '\ud83d\udd25 $streakDays-day streak!';
      body = 'You\'re building an incredible habit. Keep going!';
    } else {
      // Don't show for minor streaks
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _streakChannelId,
      _streakChannelName,
      channelDescription: _streakChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      onlyAlertOnce: true,
    );

    await _plugin.show(
      _streakNotificationIdBase + streakDays,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );

    Logger.info(
      'Streak milestone notification shown: $streakDays days',
      feature: 'Notifications',
    );
  }

  // ── Progress Reminder (immediate, contextual) ──

  /// Show a one-time reminder if the user hasn't met their daily goal yet.
  /// Best called from app lifecycle (e.g., at a specific time check).
  Future<void> showGoalProgressReminder({
    required int versesReadToday,
    required int dailyGoal,
  }) async {
    if (kIsWeb) return;
    if (!PrefUtils().isReadingReminderEnabled()) return;
    if (versesReadToday >= dailyGoal) return;

    if (!await _ensurePermission()) return;

    final remaining = dailyGoal - versesReadToday;

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      onlyAlertOnce: true,
    );

    await _plugin.show(
      _reminderNotificationId + 10,
      'Keep your momentum',
      'You have $remaining verses left to reach your daily goal. You\'ve got this!',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ── Cancel / Helpers ──

  /// Cancel all notifications managed by this service.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    Logger.info('All notifications cancelled', feature: 'Notifications');
  }

  /// Cancel only recurring notifications (verse + reminder).
  Future<void> cancelRecurring() async {
    if (kIsWeb) return;
    await _plugin.cancel(_verseNotificationId);
    await _plugin.cancel(_reminderNotificationId);
    Logger.info('Recurring notifications cancelled', feature: 'Notifications');
  }

  Future<bool> _ensurePermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning(
          'Notification permission not granted',
          feature: 'Notifications',
        );
        return false;
      }
    }
    return true;
  }

  void _onNotificationTap(NotificationResponse response) {
    Logger.info(
      'Notification tapped: ${response.id}',
      feature: 'Notifications',
    );
  }
}

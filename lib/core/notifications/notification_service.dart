import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/routes/app_routes.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/navigator_service.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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

  static const String _kahfChannelId = 'friday_kahf';
  static const String _kahfChannelName = 'Surah Al-Kahf';
  static const String _kahfChannelDescription =
      'Weekly reminder to read Surah Al-Kahf on Friday morning';

  static const int _verseNotificationId = 0;
  static const int _reminderNotificationId = 1;
  static const int _streakNotificationIdBase = 1000;
  static const int _kahfNotificationId = 2;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static NotificationService? _instance;
  static final Map<int, DateTime> _lastScheduleTime = {};
  static const Duration _minScheduleInterval = Duration(minutes: 30);

  NotificationService._();

  factory NotificationService() => _instance ??= NotificationService._();

  Future<void> initialize() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // iOS: Do NOT request permissions automatically here.
    // We request them explicitly during the onboarding flow so the
    // user sees context first. If onboarding is already completed,
    // permissions will be requested when the user toggles a setting.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Request notification permission.
  /// On Android 13+ (API 33) requests POST_NOTIFICATIONS.
  /// On iOS requests alert, badge, and sound permissions.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin == null) return true;

        // requestNotificationsPermission() requires a foreground Activity.
        // Calling it from a background context (e.g., boot receiver before
        // the first frame) causes an NPE inside the plugin.
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return false;
        }

        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosPlugin == null) return true;
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      }

      // Other platforms (macOS, Linux, Windows) — assume granted
      return true;
    } catch (e) {
      Logger.warning(
        'Notification permission request failed: $e',
        feature: 'Notifications',
      );
      return false;
    }
  }

  // ── Daily Verse ──

  /// Schedule daily verse notification. Returns true if scheduled successfully.
  Future<bool> scheduleDailyVerse() async {
    if (kIsWeb) return true;

    final pref = PrefUtils();
    if (!pref.isDailyVerseEnabled()) {
      await _plugin.cancel(_verseNotificationId);
      Logger.info(
        'Daily verse notification cancelled (disabled)',
        feature: 'Notifications',
      );
      return true;
    }

    if (_shouldThrottle(_verseNotificationId)) return true;

    if (!await _ensurePermission()) return false;
    await _plugin.cancel(_verseNotificationId);

    final surahs = QuranIndex.quranSurahs;
    final randomSurah = surahs[Random().nextInt(surahs.length)];
    final verseCount = MushafPageIndex.getVerseCount(randomSurah.id);
    final randomVerse = verseCount > 1 ? Random().nextInt(verseCount) + 1 : 1;

    final isAr = PrefUtils().getLocaleCode() == 'ar';
    final title = isAr ? 'آية اليوم' : 'Daily Verse';
    final body = isAr
        ? 'افتح حافظ لقراءة آية اليوم'
        : 'Open Hafiz to discover today\'s verse';

    const androidDetails = AndroidNotificationDetails(
      _verseChannelId,
      _verseChannelName,
      channelDescription: _verseChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final timeStr = pref.getDailyVerseTime();
    final parsedTime = _parseTimeString(timeStr, defaultHour: 8);
    final hour = parsedTime.hour;
    final minute = parsedTime.minute;
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _safeZonedSchedule(
      id: _verseNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: const NotificationDetails(android: androidDetails),
      androidScheduleMode: await _resolveScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
    );

    Logger.info(
      'Daily verse scheduled: ${randomSurah.nameEnglish} $randomVerse at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      feature: 'Notifications',
    );
    return true;
  }

  // ── Reading Reminder ──

  /// Schedule reading reminder notification. Returns true if scheduled successfully.
  Future<bool> scheduleReadingReminder() async {
    if (kIsWeb) return true;

    final pref = PrefUtils();
    if (!pref.isReadingReminderEnabled()) {
      await _plugin.cancel(_reminderNotificationId);
      Logger.info(
        'Reading reminder cancelled (disabled)',
        feature: 'Notifications',
      );
      return true;
    }

    if (_shouldThrottle(_reminderNotificationId)) return true;

    if (!await _ensurePermission()) return false;
    await _plugin.cancel(_reminderNotificationId);

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
    );

    final isAr = PrefUtils().getLocaleCode() == 'ar';

    final timeStr = pref.getReadingReminderTime();
    final parsedTime = _parseTimeString(timeStr, defaultHour: 20);
    final hour = parsedTime.hour;
    final minute = parsedTime.minute;
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _safeZonedSchedule(
      id: _reminderNotificationId,
      title: isAr ? 'وقت القرآن' : 'Time for Quran',
      body: isAr
          ? 'حافظ على ورد القرآن اليومي \u2014 افتح حافظ'
          : 'Keep your daily reading habit alive \u2014 open Hafiz',
      scheduledDate: scheduledDate,
      details: const NotificationDetails(android: androidDetails),
      androidScheduleMode: await _resolveScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
    );

    Logger.info(
      'Reading reminder scheduled at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      feature: 'Notifications',
    );
    return true;
  }

  // ── Streak Milestone (immediate) ──

  /// Show an immediate notification celebrating a streak milestone.
  /// Call this when the app detects a streak achievement.
  Future<void> showStreakMilestone(int streakDays) async {
    if (kIsWeb) return;
    if (!await _ensurePermission()) return;

    final String title;
    final String body;

    final isAr = PrefUtils().getLocaleCode() == 'ar';

    if (streakDays == 7) {
      title = isAr ? '\u2728 أسبوع كامل!' : '\u2728 One week streak!';
      body = isAr
          ? 'قرأت القرآن 7 أيام متتالية. استمر!'
          : 'You\'ve read Quran for 7 days in a row. Keep it up!';
    } else if (streakDays == 30) {
      title = isAr ? '\ud83c\udf1f 30 يومًا!' : '\ud83c\udf1f 30-day streak!';
      body = isAr
          ? 'إخلاص رائع! شهر كامل من القراءة اليومية.'
          : 'Amazing dedication! A full month of daily reading.';
    } else if (streakDays % 10 == 0) {
      title = isAr
          ? '\ud83d\udd25 سلسلة $streakDays يوم!'
          : '\ud83d\udd25 $streakDays-day streak!';
      body = isAr
          ? 'تبني عادة رائعة. واصل!'
          : 'You\'re building an incredible habit. Keep going!';
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
    final isAr = PrefUtils().getLocaleCode() == 'ar';

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
      isAr ? 'حافظ على زخمك' : 'Keep your momentum',
      isAr
          ? 'تبقى $remaining آيات لتحقيق هدفك اليومي. أنت قادر!'
          : 'You have $remaining verses left to reach your daily goal. You\'ve got this!',
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

  /// Cancel only recurring notifications (verse + reminder + kahf).
  Future<void> cancelRecurring() async {
    if (kIsWeb) return;
    await _plugin.cancel(_verseNotificationId);
    await _plugin.cancel(_reminderNotificationId);
    await _plugin.cancel(_kahfNotificationId);
    Logger.info('Recurring notifications cancelled', feature: 'Notifications');
  }

  /// Cancel daily verse notification only.
  Future<void> cancelDailyVerse() async {
    if (kIsWeb) return;
    await _plugin.cancel(_verseNotificationId);
    Logger.info('Daily verse notification cancelled', feature: 'Notifications');
  }

  /// Cancel reading reminder notification only.
  Future<void> cancelReadingReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_reminderNotificationId);
    Logger.info('Reading reminder cancelled', feature: 'Notifications');
  }

  /// Cancel Friday Kahf notification only.
  Future<void> cancelFridayKahf() async {
    if (kIsWeb) return;
    await _plugin.cancel(_kahfNotificationId);
    Logger.info('Friday Kahf notification cancelled', feature: 'Notifications');
  }

  Future<bool> _ensurePermission() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      Logger.warning(
        'Notification permission not granted',
        feature: 'Notifications',
      );
      return false;
    }
    return true;
  }

  /// Returns the appropriate schedule mode for Android.
  /// Falls back to [AndroidScheduleMode.inexactAllowWhileIdle] if exact alarms
  /// are not permitted (Android 12+ requires SCHEDULE_EXACT_ALARM permission).
  /// Schedules a notification, catching exact-alarm permission errors and
  /// retrying with an inexact schedule mode.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.message?.contains('exact_alarms_not_permitted') == true) {
        Logger.warning(
          'Exact alarm permission revoked, falling back to inexact: $e',
          feature: 'Notifications',
        );
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } else {
        rethrow;
      }
    } on RangeError catch (e, stack) {
      // Defensive breadcrumb to help identify the source of RangeErrors
      // that may come from flutter_local_notifications internals.
      Logger.error(
        'RangeError during zonedSchedule '
        '(id=$id, matchDateTimeComponents=$matchDateTimeComponents, '
        'scheduledDate=${scheduledDate.toIso8601String()}): $e',
        feature: 'Notifications',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    try {
      final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
      if (canScheduleExact ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      Logger.warning('Failed to check exact alarm permission: $e', feature: 'Notifications');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static bool _shouldThrottle(int notificationId) {
    final last = _lastScheduleTime[notificationId];
    if (last == null) {
      _lastScheduleTime[notificationId] = DateTime.now();
      return false;
    }
    final elapsed = DateTime.now().difference(last);
    if (elapsed < _minScheduleInterval) return true;
    _lastScheduleTime[notificationId] = DateTime.now();
    return false;
  }

  // ── Friday Surah Al-Kahf ──

  /// Schedule Friday Kahf notification. Returns true if scheduled successfully.
  Future<bool> scheduleFridayKahf() async {
    if (kIsWeb) return true;

    final pref = PrefUtils();
    if (!pref.isFridayKahfEnabled()) {
      await _plugin.cancel(_kahfNotificationId);
      Logger.info(
        'Friday Kahf notification cancelled (disabled)',
        feature: 'Notifications',
      );
      return true;
    }

    if (_shouldThrottle(_kahfNotificationId)) return true;

    if (!await _ensurePermission()) return false;
    await _plugin.cancel(_kahfNotificationId);

    const androidDetails = AndroidNotificationDetails(
      _kahfChannelId,
      _kahfChannelName,
      channelDescription: _kahfChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    final isAr = PrefUtils().getLocaleCode() == 'ar';
    final timeStr = pref.getFridayKahfTime();
    final parsedTime = _parseTimeString(timeStr, defaultHour: 6);
    final hour = parsedTime.hour;
    final minute = parsedTime.minute;
    final scheduledDate = _nextInstanceOfFridayTime(hour, minute);

    await _safeZonedSchedule(
      id: _kahfNotificationId,
      title: isAr ? 'سورة الكهف' : 'Surah Al-Kahf',
      body: isAr
          ? 'يوم الجمعة \u2014 اقرأ سورة الكهف قبل صلاة الجمعة'
          : 'It\'s Friday \u2014 read Surah Al-Kahf before Friday prayer',
      scheduledDate: scheduledDate,
      details: const NotificationDetails(android: androidDetails),
      androidScheduleMode: await _resolveScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'surah:18',
    );

    Logger.info(
      'Friday Kahf scheduled at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      feature: 'Notifications',
    );
    return true;
  }

  /// Safely parses a time string in "HH:mm" format.
  /// Falls back to [defaultHour]:00 if malformed.
  static ({int hour, int minute}) _parseTimeString(String timeStr, {required int defaultHour}) {
    final parts = timeStr.split(':');
    if (parts.length < 2) {
      Logger.warning('Malformed time string: "$timeStr", using default $defaultHour:00', feature: 'Notifications');
      return (hour: defaultHour, minute: 0);
    }
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) {
      Logger.warning('Invalid time values in "$timeStr", using default $defaultHour:00', feature: 'Notifications');
      return (hour: defaultHour, minute: 0);
    }
    return (hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfFridayTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != DateTime.friday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    Logger.info(
      'Notification tapped: ${response.id}',
      feature: 'Notifications',
    );
    final payload = response.payload;
    if (payload != null && payload.startsWith('surah:')) {
      final surahId = int.tryParse(payload.replaceFirst('surah:', ''));
      if (surahId != null) {
        final surah = QuranIndex.quranSurahs.firstWhere(
          (s) => s.id == surahId,
          orElse: () {
            Logger.warning('Invalid surahId: $surahId', feature: 'Notification');
            return Surah(surahId, 'Surah $surahId', 'سورة $surahId');
          },
        );
        NavigatorService.pushNamed(
          AppRoutes.surahPage,
          arguments: surah,
        );
      }
    }
  }
}

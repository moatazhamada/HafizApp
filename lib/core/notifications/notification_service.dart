import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/logger.dart';
import '../utils/pref_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _dailyVerseChannelId = 'daily_verse';
  static const String _reminderChannelId = 'reading_reminder';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      Logger.info('NotificationService initialized', feature: 'Notifications');
    } catch (e, stack) {
      Logger.error(
        'Failed to initialize NotificationService',
        feature: 'Notifications',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.info(
      'Notification tapped: ${response.payload}',
      feature: 'Notifications',
    );
  }

  Future<bool> requestPermission() async {
    try {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      bool? granted;
      if (android != null) {
        granted = await android.requestNotificationsPermission();
      }
      if (ios != null) {
        granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return granted ?? false;
    } catch (e) {
      Logger.error(
        'Failed to request notification permission',
        feature: 'Notifications',
        error: e,
      );
      return false;
    }
  }

  Future<void> scheduleDailyVerseNotification({
    required int hour,
    required int minute,
    String? title,
    String? body,
  }) async {
    if (!_initialized) await initialize();

    try {
      final enabled = PrefUtils().getString('daily_verse_enabled') == 'true';
      if (!enabled) return;

      await _notifications.zonedSchedule(
        0,
        title ?? 'daily_verse_title'.tr,
        body ?? 'daily_verse_body'.tr,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyVerseChannelId,
            'Daily Verse',
            channelDescription: 'Daily Quran verse notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      Logger.info(
        'Scheduled daily verse notification for $hour:$minute',
        feature: 'Notifications',
      );
    } catch (e) {
      Logger.error(
        'Failed to schedule daily verse notification',
        feature: 'Notifications',
        error: e,
      );
    }
  }

  Future<void> scheduleReadingReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    try {
      final enabled =
          PrefUtils().getString('reading_reminder_enabled') == 'true';
      if (!enabled) return;

      await _notifications.zonedSchedule(
        1,
        'reading_reminder_title'.tr,
        'reading_reminder_body'.tr,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            'Reading Reminder',
            channelDescription: 'Daily reading reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      Logger.error(
        'Failed to schedule reading reminder',
        feature: 'Notifications',
        error: e,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyVerseChannelId,
          'Daily Verse',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

extension StringTrExtension on String {
  String get tr => this;
}

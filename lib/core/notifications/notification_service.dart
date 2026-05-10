import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class DailyVerseNotificationService {
  static const String _channelId = 'daily_verse';
  static const String _channelName = 'Daily Verse';
  static const String _channelDescription = 'Daily Quran verse reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static DailyVerseNotificationService? _instance;

  DailyVerseNotificationService._();

  factory DailyVerseNotificationService() =>
      _instance ??= DailyVerseNotificationService._();

  Future<void> initialize() async {
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
    if (!Platform.isAndroid) return true;

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

  Future<void> scheduleDailyVerse() async {
    final pref = PrefUtils();
    if (!pref.isDailyVerseEnabled()) {
      await _plugin.cancelAll();
      Logger.info(
        'Daily verse notification cancelled (disabled)',
        feature: 'Notifications',
      );
      return;
    }

    // Request permission before scheduling on Android
    if (Platform.isAndroid) {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        Logger.warning(
          'Notification permission not granted, skipping schedule',
          feature: 'Notifications',
        );
        return;
      }
    }

    await _plugin.cancelAll();

    final surahs = QuranIndex.quranSurahs;
    final randomSurah = surahs[Random().nextInt(surahs.length)];
    final verseCount = MushafPageIndex.getVerseCount(randomSurah.id);
    final randomVerse = verseCount > 1 ? Random().nextInt(verseCount) + 1 : 1;

    final title = '${randomSurah.nameEnglish} ${randomSurah.nameArabic}';
    final body = 'Verse $randomVerse \u2014 Open Hafiz to read';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.periodicallyShow(
      0,
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

  /// Cancel all scheduled daily verse notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    Logger.info('All notifications cancelled', feature: 'Notifications');
  }

  void _onNotificationTap(NotificationResponse response) {
    Logger.info('Daily verse notification tapped', feature: 'Notifications');
  }
}

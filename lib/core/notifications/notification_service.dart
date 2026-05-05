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

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> scheduleDailyVerse() async {
    final pref = PrefUtils();
    if (!pref.isDailyVerseEnabled()) return;

    await _plugin.cancelAll();

    final surahs = QuranIndex.quranSurahs;
    final randomSurah = surahs[Random().nextInt(surahs.length)];
    final verseCount = MushafPageIndex.getVerseCount(randomSurah.id);
    final randomVerse = verseCount > 1 ? Random().nextInt(verseCount) + 1 : 1;

    final title = '${randomSurah.nameEnglish} ${randomSurah.nameArabic}';
    final body = 'Verse $randomVerse — Open Hafiz to read';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    // Use simple periodic show instead of zonedSchedule to avoid timezone dependency.
    await _plugin.periodicallyShow(
      0,
      title,
      body,
      RepeatInterval.daily,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    Logger.info(
      'Daily verse scheduled: ${randomSurah.nameEnglish} $randomVerse',
      feature: 'Notifications',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    Logger.info('Daily verse notification tapped', feature: 'Notifications');
  }
}

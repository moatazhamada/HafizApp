import 'dart:async';
import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_app/data/datasource/random_verse/random_verse_remote_data_source.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/injection_container.dart';

class HomeWidgetService {
  static const _arabicKey = 'widget_verse_arabic';
  static const _textKey = 'widget_verse_text';
  static const _refKey = 'widget_verse_ref';
  static const _chapterIdKey = 'widget_chapter_id';
  static const _verseNumberKey = 'widget_verse_number';

  /// Refresh the widget every hour with a new random verse.
  static const _refreshInterval = Duration(hours: 1);

  Timer? _refreshTimer;

  Future<void> initialize() async {
    try {
      // setAppGroupId is only needed on iOS/macOS.
      if (Platform.isIOS || Platform.isMacOS) {
        await HomeWidget.setAppGroupId('group.com.hafiz.app');
      }

      HomeWidget.widgetClicked.listen(_onWidgetClicked);

      // Initial refresh
      await _refreshWidget();

      // Periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        _refreshWidget();
      });

      // Refresh when locale changes
      LocaleController.notifier.addListener(_onLocaleChanged);
    } catch (e) {
      Logger.warning('HomeWidget not available on this platform: $e',
          feature: 'HomeWidget');
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    LocaleController.notifier.removeListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    _refreshWidget();
  }

  void _onWidgetClicked(Uri? uri) {
    Logger.info('Widget clicked: $uri', feature: 'HomeWidget');
  }

  Future<void> _refreshWidget() async {
    try {
      final ds = sl<RandomVerseRemoteDataSource>();
      final verse = await ds.fetchRandomVerse();
      if (verse == null) {
        await _setPlaceholder();
        return;
      }

      final isArabic = LocaleController.notifier.value.languageCode == 'ar';
      final displayText = isArabic ? verse.arabicText : verse.englishText;

      // Save to both SharedPreferences (for native fallback) and
      // HomeWidget plugin data store (preferred).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_arabicKey, verse.arabicText);
      await prefs.setString(_textKey, displayText);
      await prefs.setString(_refKey, '— ${verse.verseKey}');
      await prefs.setString(_chapterIdKey, verse.chapterId.toString());
      await prefs.setString(_verseNumberKey, verse.verseNumber.toString());

      await HomeWidget.saveWidgetData<String>(_arabicKey, verse.arabicText);
      await HomeWidget.saveWidgetData<String>(_textKey, displayText);
      await HomeWidget.saveWidgetData<String>(_refKey, '— ${verse.verseKey}');
      await HomeWidget.saveWidgetData<String>(
        _chapterIdKey,
        verse.chapterId.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        _verseNumberKey,
        verse.verseNumber.toString(),
      );

      await HomeWidget.updateWidget(
        name: 'HafizAppWidgetProvider',
        androidName: 'HafizAppWidgetProvider',
        uri: Uri.parse('hafiz://verse/${verse.chapterId}/${verse.verseNumber}'),
      );

      Logger.info('HomeWidget updated: ${verse.verseKey}',
          feature: 'HomeWidget');
    } catch (e) {
      Logger.warning('HomeWidget refresh failed: $e', feature: 'HomeWidget');
      await _setPlaceholder();
    }
  }

  Future<void> _setPlaceholder() async {
    const arabic = 'اقْرَأْ بِاسْمِ رَبِّكَ';
    const english = 'Read in the name of your Lord';
    const ref = '— 96:1';

    final isArabic = LocaleController.notifier.value.languageCode == 'ar';
    final displayText = isArabic ? arabic : english;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_arabicKey, arabic);
    await prefs.setString(_textKey, displayText);
    await prefs.setString(_refKey, ref);
    await prefs.setString(_chapterIdKey, '96');
    await prefs.setString(_verseNumberKey, '1');

    await HomeWidget.saveWidgetData<String>(_arabicKey, arabic);
    await HomeWidget.saveWidgetData<String>(_textKey, displayText);
    await HomeWidget.saveWidgetData<String>(_refKey, ref);
    await HomeWidget.saveWidgetData<String>(_chapterIdKey, '96');
    await HomeWidget.saveWidgetData<String>(_verseNumberKey, '1');

    await HomeWidget.updateWidget(
      name: 'HafizAppWidgetProvider',
      androidName: 'HafizAppWidgetProvider',
      uri: Uri.parse('hafiz://verse/96/1'),
    );
  }

  /// Force a widget refresh from outside (e.g. after user adds widget).
  Future<void> forceRefresh() async {
    await _refreshWidget();
  }
}

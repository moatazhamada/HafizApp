import 'dart:async';
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

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.hafiz.app');

    HomeWidget.widgetClicked.listen(_onWidgetClicked);

    try {
      await _refreshWidget();
    } catch (e) {
      Logger.warning('HomeWidget init failed: $e', feature: 'HomeWidget');
      await _setPlaceholder();
    }

    Timer.periodic(_refreshInterval, (_) {
      _refreshWidget();
    });

    // Also refresh when locale changes (user may switch language)
    LocaleController.notifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    _refreshWidget();
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
      // In Arabic mode show only Arabic; otherwise show translation (English).
      final displayText = isArabic ? verse.arabicText : verse.englishText;

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
      );

      Logger.info('HomeWidget updated: ${verse.verseKey}', feature: 'HomeWidget');
    } catch (e) {
      Logger.warning('HomeWidget refresh failed: $e', feature: 'HomeWidget');
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

    try {
      await HomeWidget.updateWidget(name: 'HafizAppWidgetProvider', androidName: 'HafizAppWidgetProvider');
    } catch (_) {}
  }

  void _onWidgetClicked(Uri? uri) {
    if (uri != null) {
      Logger.info('Widget clicked: $uri', feature: 'HomeWidget');
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_app/data/datasource/random_verse/random_verse_remote_data_source.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/injection_container.dart';

class HomeWidgetService {
  static const _arabicKey = 'widget_verse_arabic';
  static const _englishKey = 'widget_verse_english';
  static const _refKey = 'widget_verse_ref';
  static const _chapterIdKey = 'widget_chapter_id';
  static const _verseNumberKey = 'widget_verse_number';

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.hafiz.app');

    HomeWidget.widgetClicked.listen(_onWidgetClicked);

    try {
      await _refreshWidget();
    } catch (e) {
      Logger.warning('HomeWidget init failed: $e', feature: 'HomeWidget');
      await _setPlaceholder();
    }

    Timer.periodic(const Duration(hours: 6), (_) {
      _refreshWidget();
    });
  }

  Future<void> _refreshWidget() async {
    try {
      final ds = sl<RandomVerseRemoteDataSource>();
      final verse = await ds.fetchRandomVerse();
      if (verse == null) {
        await _setPlaceholder();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_arabicKey, verse.arabicText);
      await prefs.setString(_englishKey, verse.englishText);
      await prefs.setString(_refKey, '— ${verse.verseKey}');
      await prefs.setString(_chapterIdKey, verse.chapterId.toString());
      await prefs.setString(_verseNumberKey, verse.verseNumber.toString());

      await HomeWidget.saveWidgetData<String>(_arabicKey, verse.arabicText);
      await HomeWidget.saveWidgetData<String>(
        _englishKey,
        verse.englishText,
      );
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_arabicKey, arabic);
    await prefs.setString(_englishKey, english);
    await prefs.setString(_refKey, ref);
    await prefs.setString(_chapterIdKey, '96');
    await prefs.setString(_verseNumberKey, '1');

    await HomeWidget.saveWidgetData(_arabicKey, arabic);
    await HomeWidget.saveWidgetData(_englishKey, english);
    await HomeWidget.saveWidgetData(_refKey, ref);
    await HomeWidget.saveWidgetData(_chapterIdKey, '96');
    await HomeWidget.saveWidgetData(_verseNumberKey, '1');

    try {
      await HomeWidget.updateWidget(name: 'HafizAppWidgetProvider', androidName: 'HafizAppWidgetProvider');
    } catch (_) {}
  }

  void _onNotificationTap(Uri? uri) {
    Logger.info('Widget tapped', feature: 'HomeWidget');
  }

  void _onWidgetClicked(Uri? uri) {
    if (uri != null) {
      Logger.info('Widget clicked: $uri', feature: 'HomeWidget');
    }
  }
}

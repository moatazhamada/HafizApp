import 'dart:convert';

import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

class ReadingPreferences {
  // ── Per-surah scroll offset ──

  Future<void> setSurahOffset(int surahId, double offset) async {
    await PrefUtils.prefs.setDouble('offset_$surahId', offset);
  }

  double? getSurahOffset(int surahId) {
    try {
      return PrefUtils.prefs.getDouble('offset_$surahId');
    } catch (e) {
      Logger.warning(
        'Failed to get surah offset for surah $surahId: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  Future<void> setSurahVerseIndex(int surahId, int index) async {
    await PrefUtils.prefs.setInt('verse_index_$surahId', index);
  }

  int? getSurahVerseIndex(int surahId) {
    try {
      return PrefUtils.prefs.getInt('verse_index_$surahId');
    } catch (e) {
      Logger.warning(
        'Failed to get verse index for surah $surahId: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  // ── Verse View Mode (false = Continuous/Mushaf, true = Single Line) ──

  Future<void> setVerseViewMode(bool isSingleLine) async {
    await PrefUtils.prefs.setBool('isSingleLine', isSingleLine);
  }

  bool getVerseViewMode() {
    try {
      return PrefUtils.prefs.getBool('isSingleLine') ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to get verse view mode: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  // ── Quran Font Size ──

  double getQuranFontSize() {
    try {
      final raw = PrefUtils.prefs.getDouble('quranFontSize') ?? 24.0;
      return raw.clamp(16.0, 40.0);
    } catch (e) {
      return 24.0;
    }
  }

  Future<void> setQuranFontSize(double size) async {
    await PrefUtils.prefs.setDouble('quranFontSize', size);
  }

  // ── Orientation Mode: 'system', 'portrait', 'landscape' ──

  String getOrientationMode() {
    try {
      return PrefUtils.prefs.getString('orientationMode') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  Future<void> setOrientationMode(String mode) async {
    await PrefUtils.prefs.setString('orientationMode', mode);
  }

  // ── Default Quran View: 'surah', 'mushaf' ──

  String getDefaultQuranView() {
    try {
      return PrefUtils.prefs.getString('defaultQuranView') ?? 'surah';
    } catch (e) {
      return 'surah';
    }
  }

  Future<void> setDefaultQuranView(String view) async {
    await PrefUtils.prefs.setString('defaultQuranView', view);
  }

  // ── Reading Navigation Mode: 'scroll', 'page' ──

  String getReadingNavMode() {
    try {
      return PrefUtils.prefs.getString('readingNavMode') ?? 'scroll';
    } catch (e) {
      return 'scroll';
    }
  }

  Future<void> setReadingNavMode(String mode) async {
    await PrefUtils.prefs.setString('readingNavMode', mode);
  }

  // ── Mushaf Type & Page ──

  String? getMushafType() {
    try {
      return PrefUtils.prefs.getString('mushafType');
    } catch (e) {
      return null;
    }
  }

  Future<void> setMushafType(String type) async {
    await PrefUtils.prefs.setString('mushafType', type);
  }

  int getMushafLastPage() => PrefUtils.prefs.getInt('mushafLastPage') ?? 1;

  Future<void> setMushafLastPage(int page) async =>
      PrefUtils.prefs.setInt('mushafLastPage', page);

  int getMushafLastPageForType(String type) =>
      PrefUtils.prefs.getInt('mushafLastPage_$type') ?? 1;

  Future<void> setMushafLastPageForType(String type, int page) async =>
      PrefUtils.prefs.setInt('mushafLastPage_$type', page);

  // ── Keep Screen On ──

  static const String _keepScreenOnKey = 'keep_screen_on';

  bool isKeepScreenOn() {
    try {
      return PrefUtils.prefs.getBool(_keepScreenOnKey) ?? true;
    } catch (e) {
      Logger.warning(
        'Failed to get keep screen on: $e',
        feature: 'Preferences',
      );
      return true;
    }
  }

  Future<void> setKeepScreenOn(bool value) async {
    await PrefUtils.prefs.setBool(_keepScreenOnKey, value);
  }

  // ── Last Read Surah ──

  String _surahToJson(Surah surah) => json.encode(surah.toMap());

  Future<void> saveLastReadSurah(Surah surah) async {
    await PrefUtils.prefs.setString('surah', _surahToJson(surah));
  }

  Surah? getLastReadSurah() {
    try {
      final String? jsonString = PrefUtils.prefs.getString('surah');
      return jsonString != null ? Surah.fromJson(jsonString) : null;
    } catch (e) {
      Logger.warning(
        'Failed to get last read surah: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }
}

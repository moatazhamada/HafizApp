//ignore: unused_import
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;

  PrefUtils() {
    // init();
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
    });
  }

  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    debugPrint('SharedPreference Initialized');
  }

  ///will clear all the data stored in preference
  void clearPreferencesData() async {
    _sharedPreferences!.clear();
  }

  // Theme Mode: 'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    await _sharedPreferences!.setString('themeMode', mode);
  }

  String getThemeMode() {
    try {
      return _sharedPreferences!.getString('themeMode') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  // Deprecated: getIsDarkMode - compatibility shim
  bool getIsDarkMode() {
    final mode = getThemeMode();
    if (mode == 'dark') return true;
    if (mode == 'light') return false;
    // System default fallback handled in UI or by platform query
    // For simple boolean query (like legacy calls), we might default to system brightness
    // But direct calls to PlatformDispatcher are better done in the UI.
    // Here we just return false (light) as default if system is chosen but boolean required.
    // OR: We can migrate caller to check getThemeMode.
    return false;
  }

  // Deprecated: setIsDarkMode - compatibility shim
  Future<void> setIsDarkMode(bool value) {
    return setThemeMode(value ? 'dark' : 'light');
  }

  // Convert Surah object to JSON string
  String toJson(Surah surah) => json.encode(surah.toMap());

  // Store Surah object in SharedPreferences
  Future<void> saveLastReadSurah(Surah surah) async {
    await _sharedPreferences!.setString('surah', toJson(surah));
  }

  // Retrieve Surah object from SharedPreferences
  Surah? getLastReadSurah() {
    final String? jsonString = _sharedPreferences!.getString('surah');
    return jsonString != null ? Surah.fromJson(jsonString) : null;
  }

  // Locale persistence (ar/en/system)
  Future<void> setLocaleCode(String code) async {
    await _sharedPreferences!.setString('localeCode', code);
  }

  String getLocaleCode() {
    try {
      return _sharedPreferences!.getString('localeCode') ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  // Per-surah scroll offset persistence (fallback when hydration isn't ready)
  Future<void> setSurahOffset(int surahId, double offset) async {
    await _sharedPreferences!.setDouble('offset_$surahId', offset);
  }

  double? getSurahOffset(int surahId) {
    try {
      return _sharedPreferences!.getDouble('offset_$surahId');
    } catch (_) {
      return null;
    }
  }

  Future<void> setSurahVerseIndex(int surahId, int index) async {
    await _sharedPreferences!.setInt('verse_index_$surahId', index);
  }

  int? getSurahVerseIndex(int surahId) {
    try {
      return _sharedPreferences!.getInt('verse_index_$surahId');
    } catch (_) {
      return null;
    }
  }

  // Verse View Mode (false = Continuous/Mushaf, true = Single Line)
  Future<void> setVerseViewMode(bool isSingleLine) async {
    await _sharedPreferences!.setBool('isSingleLine', isSingleLine);
  }

  bool getVerseViewMode() {
    try {
      return _sharedPreferences!.getBool('isSingleLine') ??
          false; // Default Continuous
    } catch (_) {
      return false;
    }
  }
}

//ignore: unused_import
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
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
  Future<void> clearPreferencesData() async {
    await _sharedPreferences!.clear();
  }

  // Theme Mode: 'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    await _sharedPreferences!.setString('themeMode', mode);
  }

  String getThemeMode() {
    try {
      return _sharedPreferences!.getString('themeMode') ?? 'system';
    } catch (e) {
      Logger.warning('Failed to get theme mode: $e', feature: 'Preferences');
      return 'system';
    }
  }

  // Deprecated: getIsDarkMode - compatibility shim
  bool getIsDarkMode() {
    final mode = getThemeMode();
    if (mode == 'dark') return true;
    if (mode == 'light') return false;
    // System default fallback: Check platform brightness
    if (mode == 'system') {
      try {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
      } catch (e) {
        Logger.warning(
          'Failed to get platform brightness: $e',
          feature: 'Preferences',
        );
        return false;
      }
    }
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
    try {
      final String? jsonString = _sharedPreferences!.getString('surah');
      return jsonString != null ? Surah.fromJson(jsonString) : null;
    } catch (e) {
      Logger.warning(
        'Failed to get last read surah: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  // Locale persistence (ar/en/system)
  Future<void> setLocaleCode(String code) async {
    await _sharedPreferences!.setString('localeCode', code);
  }

  String getLocaleCode() {
    try {
      return _sharedPreferences!.getString('localeCode') ?? 'system';
    } catch (e) {
      Logger.warning('Failed to get locale code: $e', feature: 'Preferences');
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
    } catch (e) {
      Logger.warning(
        'Failed to get surah offset for surah $surahId: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  Future<void> setSurahVerseIndex(int surahId, int index) async {
    await _sharedPreferences!.setInt('verse_index_$surahId', index);
  }

  int? getSurahVerseIndex(int surahId) {
    try {
      return _sharedPreferences!.getInt('verse_index_$surahId');
    } catch (e) {
      Logger.warning(
        'Failed to get verse index for surah $surahId: $e',
        feature: 'Preferences',
      );
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
    } catch (e) {
      Logger.warning(
        'Failed to get verse view mode: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  // Recitation settings
  Future<void> setRecitationProvider(String provider) async {
    await _sharedPreferences!.setString('recitation_provider', provider);
  }

  String getRecitationProvider() {
    try {
      return _sharedPreferences!.getString('recitation_provider') ??
          'local_whisper';
    } catch (e) {
      Logger.warning(
        'Failed to get recitation provider: $e',
        feature: 'Preferences',
      );
      return 'local_whisper';
    }
  }

  Future<void> setQiraatEdition(String edition) async {
    await _sharedPreferences!.setString('qiraat_edition', edition);
  }

  String getQiraatEdition() {
    try {
      return _sharedPreferences!.getString('qiraat_edition') ?? 'quran-uthmani';
    } catch (e) {
      Logger.warning(
        'Failed to get qiraat edition: $e',
        feature: 'Preferences',
      );
      return 'quran-uthmani';
    }
  }

  Future<void> setReciterId(int id) async {
    await _sharedPreferences!.setInt('reciter_id', id);
  }

  int getReciterId() {
    try {
      return _sharedPreferences!.getInt('reciter_id') ?? 7;
    } catch (e) {
      Logger.warning('Failed to get reciter id: $e', feature: 'Preferences');
      return 7;
    }
  }

  Future<void> setCustomAsrEndpoint(String url) async {
    await _sharedPreferences!.setString('custom_asr_endpoint', url);
  }

  String getCustomAsrEndpoint() {
    try {
      return _sharedPreferences!.getString('custom_asr_endpoint') ?? '';
    } catch (e) {
      Logger.warning(
        'Failed to get custom ASR endpoint: $e',
        feature: 'Preferences',
      );
      return '';
    }
  }

  Future<void> setWhisperModel(String model) async {
    await _sharedPreferences!.setString('whisper_model', model);
  }

  String getWhisperModel() {
    try {
      return _sharedPreferences!.getString('whisper_model') ?? 'base';
    } catch (e) {
      Logger.warning('Failed to get whisper model: $e', feature: 'Preferences');
      return 'base';
    }
  }

  Future<void> setQrcHafzLevel(int level) async {
    await _sharedPreferences!.setInt('qrc_hafz_level', level);
  }

  int getQrcHafzLevel() {
    try {
      return _sharedPreferences!.getInt('qrc_hafz_level') ?? 1;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc hafz level: $e',
        feature: 'Preferences',
      );
      return 1;
    }
  }

  Future<void> setQrcTajweedLevel(int level) async {
    await _sharedPreferences!.setInt('qrc_tajweed_level', level);
  }

  int getQrcTajweedLevel() {
    try {
      return _sharedPreferences!.getInt('qrc_tajweed_level') ?? 3;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc tajweed level: $e',
        feature: 'Preferences',
      );
      return 3;
    }
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    await _sharedPreferences!.setBool('cloud_sync_enabled', enabled);
  }

  bool getCloudSyncEnabled() {
    try {
      return _sharedPreferences!.getBool('cloud_sync_enabled') ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to get cloud sync enabled: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  Future<void> setCloudSyncDirection(String direction) async {
    await _sharedPreferences!.setString('cloud_sync_direction', direction);
  }

  String getCloudSyncDirection() {
    try {
      return _sharedPreferences!.getString('cloud_sync_direction') ??
          'bidirectional';
    } catch (e) {
      Logger.warning(
        'Failed to get cloud sync direction: $e',
        feature: 'Preferences',
      );
      return 'bidirectional';
    }
  }

  String? getMushafType() {
    try {
      return _sharedPreferences?.getString('mushafType');
    } catch (e) {
      return null;
    }
  }

  Future<void> setMushafType(String type) async {
    await _sharedPreferences!.setString('mushafType', type);
  }

  bool getOnboardingCompleted() {
    try {
      return _sharedPreferences?.getBool('onboardingCompleted') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _sharedPreferences!.setBool('onboardingCompleted', value);
  }

  // Quran Font Size
  double getQuranFontSize() {
    try {
      return _sharedPreferences?.getDouble('quranFontSize') ?? 24.0;
    } catch (e) {
      return 24.0;
    }
  }

  Future<void> setQuranFontSize(double size) async {
    await _sharedPreferences!.setDouble('quranFontSize', size);
  }

  // Orientation Mode: 'system', 'portrait', 'landscape'
  String getOrientationMode() {
    try {
      return _sharedPreferences?.getString('orientationMode') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  Future<void> setOrientationMode(String mode) async {
    await _sharedPreferences!.setString('orientationMode', mode);
  }

  // Default Quran View: 'surah', 'mushaf'
  String getDefaultQuranView() {
    try {
      return _sharedPreferences?.getString('defaultQuranView') ?? 'surah';
    } catch (e) {
      return 'surah';
    }
  }

  Future<void> setDefaultQuranView(String view) async {
    await _sharedPreferences!.setString('defaultQuranView', view);
  }

  // Reading Navigation Mode: 'scroll', 'page'
  String getReadingNavMode() {
    try {
      return _sharedPreferences?.getString('readingNavMode') ?? 'scroll';
    } catch (e) {
      return 'scroll';
    }
  }

  Future<void> setReadingNavMode(String mode) async {
    await _sharedPreferences!.setString('readingNavMode', mode);
  }
}

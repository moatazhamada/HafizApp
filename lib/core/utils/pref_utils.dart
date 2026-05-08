//ignore: unused_import
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;
  static Completer<SharedPreferences>? _initCompleter;

  PrefUtils() {
    init();
  }

  /// Initialise SharedPreferences. Safe to call multiple times; concurrent
  /// callers will coalesce on the same Completer.
  Future<void> init() async {
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<SharedPreferences>();
    try {
      final prefs = await SharedPreferences.getInstance();
      _sharedPreferences = prefs;
      _initCompleter!.complete(prefs);
      debugPrint('SharedPreference Initialized');
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Ensures [_sharedPreferences] is available. If init() was never awaited,
  /// this will block until it completes. Returns the prefs instance.
  ///
  /// For synchronous getters that run after init(), [_sharedPreferences] is
  /// already set and this is effectively a no-op assertion.
  SharedPreferences _requirePrefs() {
    if (_sharedPreferences != null) return _sharedPreferences!;
    throw StateError(
      'PrefUtils: SharedPreferences accessed before init() completed. '
      'Ensure PrefUtils.init() is awaited before reading preferences.',
    );
  }

  ///will clear all the data stored in preference
  Future<void> clearPreferencesData() async {
    await _requirePrefs().clear();
  }

  // Generic int access
  Future<void> setInt(String key, int value) async {
    await _requirePrefs().setInt(key, value);
  }

  int? getInt(String key) => _requirePrefs().getInt(key);

  // Theme Mode: 'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    await _requirePrefs().setString('themeMode', mode);
  }

  String getThemeMode() {
    try {
      return _requirePrefs().getString('themeMode') ?? 'system';
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
    await _requirePrefs().setString('surah', toJson(surah));
  }

  // Retrieve Surah object from SharedPreferences
  Surah? getLastReadSurah() {
    try {
      final String? jsonString = _requirePrefs().getString('surah');
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
    await _requirePrefs().setString('localeCode', code);
  }

  String getLocaleCode() {
    try {
      return _requirePrefs().getString('localeCode') ?? 'system';
    } catch (e) {
      Logger.warning('Failed to get locale code: $e', feature: 'Preferences');
      return 'system';
    }
  }

  // Per-surah scroll offset persistence (fallback when hydration isn't ready)
  Future<void> setSurahOffset(int surahId, double offset) async {
    await _requirePrefs().setDouble('offset_$surahId', offset);
  }

  double? getSurahOffset(int surahId) {
    try {
      return _requirePrefs().getDouble('offset_$surahId');
    } catch (e) {
      Logger.warning(
        'Failed to get surah offset for surah $surahId: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  Future<void> setSurahVerseIndex(int surahId, int index) async {
    await _requirePrefs().setInt('verse_index_$surahId', index);
  }

  int? getSurahVerseIndex(int surahId) {
    try {
      return _requirePrefs().getInt('verse_index_$surahId');
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
    await _requirePrefs().setBool('isSingleLine', isSingleLine);
  }

  bool getVerseViewMode() {
    try {
      return _requirePrefs().getBool('isSingleLine') ??
          false; // Default Continuous
    } catch (e) {
      Logger.warning(
        'Failed to get verse view mode: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  // Translation settings
  bool getShowTranslation() {
    try {
      return _requirePrefs().getBool('show_translation') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setShowTranslation(bool value) async {
    try {
      await _requirePrefs().setBool('show_translation', value);
    } catch (e) {
      Logger.warning(
        'Failed to set translation pref: $e',
        feature: 'Preferences',
      );
    }
  }

  // Recitation settings
  Future<void> setRecitationProvider(String provider) async {
    await _requirePrefs().setString('recitation_provider', provider);
  }

  String getRecitationProvider() {
    try {
      return _requirePrefs().getString('recitation_provider') ??
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
    await _requirePrefs().setString('qiraat_edition', edition);
  }

  String getQiraatEdition() {
    try {
      return _requirePrefs().getString('qiraat_edition') ?? 'quran-uthmani';
    } catch (e) {
      Logger.warning(
        'Failed to get qiraat edition: $e',
        feature: 'Preferences',
      );
      return 'quran-uthmani';
    }
  }

  Future<void> setReciterId(int id) async {
    await _requirePrefs().setInt('reciter_id', id);
  }

  int getReciterId() {
    try {
      return _requirePrefs().getInt('reciter_id') ?? 7;
    } catch (e) {
      Logger.warning('Failed to get reciter id: $e', feature: 'Preferences');
      return 7;
    }
  }

  Future<void> setCustomAsrEndpoint(String url) async {
    await _requirePrefs().setString('custom_asr_endpoint', url);
  }

  String getCustomAsrEndpoint() {
    try {
      return _requirePrefs().getString('custom_asr_endpoint') ?? '';
    } catch (e) {
      Logger.warning(
        'Failed to get custom ASR endpoint: $e',
        feature: 'Preferences',
      );
      return '';
    }
  }

  Future<void> setWhisperModel(String model) async {
    await _requirePrefs().setString('whisper_model', model);
  }

  String getWhisperModel() {
    try {
      return _requirePrefs().getString('whisper_model') ?? 'base';
    } catch (e) {
      Logger.warning('Failed to get whisper model: $e', feature: 'Preferences');
      return 'base';
    }
  }

  Future<void> setQrcHafzLevel(int level) async {
    await _requirePrefs().setInt('qrc_hafz_level', level);
  }

  int getQrcHafzLevel() {
    try {
      return _requirePrefs().getInt('qrc_hafz_level') ?? 1;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc hafz level: $e',
        feature: 'Preferences',
      );
      return 1;
    }
  }

  Future<void> setQrcTajweedLevel(int level) async {
    await _requirePrefs().setInt('qrc_tajweed_level', level);
  }

  int getQrcTajweedLevel() {
    try {
      return _requirePrefs().getInt('qrc_tajweed_level') ?? 3;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc tajweed level: $e',
        feature: 'Preferences',
      );
      return 3;
    }
  }

  DateTime? getQfLastSyncAt() {
    try {
      final s = _requirePrefs().getString('qf_last_sync_at');
      return s != null ? DateTime.tryParse(s) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setQfLastSyncAt(DateTime dt) async {
    await _requirePrefs().setString('qf_last_sync_at', dt.toIso8601String());
  }

  String? getMushafType() {
    try {
      return _requirePrefs().getString('mushafType');
    } catch (e) {
      return null;
    }
  }

  Future<void> setMushafType(String type) async {
    await _requirePrefs().setString('mushafType', type);
  }

  int getMushafLastPage() => _requirePrefs().getInt('mushafLastPage') ?? 1;

  Future<void> setMushafLastPage(int page) async =>
      _requirePrefs().setInt('mushafLastPage', page);

  bool getOnboardingCompleted() {
    try {
      return _requirePrefs().getBool('onboardingCompleted') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _requirePrefs().setBool('onboardingCompleted', value);
  }

  // Quran Font Size
  double getQuranFontSize() {
    try {
      return _requirePrefs().getDouble('quranFontSize') ?? 24.0;
    } catch (e) {
      return 24.0;
    }
  }

  Future<void> setQuranFontSize(double size) async {
    await _requirePrefs().setDouble('quranFontSize', size);
  }

  // Orientation Mode: 'system', 'portrait', 'landscape'
  String getOrientationMode() {
    try {
      return _requirePrefs().getString('orientationMode') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  Future<void> setOrientationMode(String mode) async {
    await _requirePrefs().setString('orientationMode', mode);
  }

  // Default Quran View: 'surah', 'mushaf'
  String getDefaultQuranView() {
    try {
      return _requirePrefs().getString('defaultQuranView') ?? 'surah';
    } catch (e) {
      return 'surah';
    }
  }

  Future<void> setDefaultQuranView(String view) async {
    await _requirePrefs().setString('defaultQuranView', view);
  }

  // Reading Navigation Mode: 'scroll', 'page'
  String getReadingNavMode() {
    try {
      return _requirePrefs().getString('readingNavMode') ?? 'scroll';
    } catch (e) {
      return 'scroll';
    }
  }

  Future<void> setReadingNavMode(String mode) async {
    await _requirePrefs().setString('readingNavMode', mode);
  }

  // Mushaf Rendering Mode: 'text', 'ayahImages', 'glyph', 'tajweed'
  String getMushafRenderingMode() {
    try {
      return _requirePrefs().getString('mushafRenderingMode') ?? 'ayahImages';
    } catch (e) {
      return 'ayahImages';
    }
  }

  Future<void> setMushafRenderingMode(String mode) async {
    await _requirePrefs().setString('mushafRenderingMode', mode);
  }

  // Mushaf Dual Page Mode
  bool getMushafDualPage() {
    try {
      return _requirePrefs().getBool('mushafDualPage') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> setMushafDualPage(bool value) async {
    await _requirePrefs().setBool('mushafDualPage', value);
  }

  bool isDailyVerseEnabled() {
    try {
      return _requirePrefs().getBool('dailyVerseEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> setDailyVerseEnabled(bool enabled) async {
    await _requirePrefs().setBool('dailyVerseEnabled', enabled);
  }
}

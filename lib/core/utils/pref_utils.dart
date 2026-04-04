//ignore: unused_import
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;
  static final _initLock = Lock();

  PrefUtils();

  Future<void> init() async {
    if (_sharedPreferences != null) return;

    await _initLock.synchronized(() async {
      if (_sharedPreferences != null) return;
      _sharedPreferences = await SharedPreferences.getInstance();
      debugPrint('SharedPreference Initialized');
    });
  }

  /// Ensures SharedPreferences is initialized before any operation
  void _ensureInitialized() {
    if (_sharedPreferences == null) {
      throw StateError(
        'PrefUtils not initialized. Call init() before using any preferences.',
      );
    }
  }

  ///will clear all the data stored in preference
  Future<void> clearPreferencesData() async {
    _ensureInitialized();
    await _sharedPreferences!.clear();
  }

  // Theme Mode: 'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('themeMode', mode);
  }

  String getThemeMode() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('surah', toJson(surah));
    await recordReadingSession();
  }

  // Retrieve Surah object from SharedPreferences
  Surah? getLastReadSurah() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('localeCode', code);
  }

  String getLocaleCode() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('localeCode') ?? 'ar';
    } catch (e) {
      Logger.warning('Failed to get locale code: $e', feature: 'Preferences');
      return 'ar';
    }
  }

  // Per-surah scroll offset persistence (fallback when hydration isn't ready)
  Future<void> setSurahOffset(int surahId, double offset) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setDouble('offset_$surahId', offset);
  }

  double? getSurahOffset(int surahId) {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setInt('verse_index_$surahId', index);
  }

  int? getSurahVerseIndex(int surahId) {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setBool('isSingleLine', isSingleLine);
  }

  bool getVerseViewMode() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('recitation_provider', provider);
  }

  String getRecitationProvider() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('qiraat_edition', edition);
  }

  String getQiraatEdition() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setInt('reciter_id', id);
  }

  int getReciterId() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getInt('reciter_id') ?? 7;
    } catch (e) {
      Logger.warning('Failed to get reciter id: $e', feature: 'Preferences');
      return 7;
    }
  }

  String getReciterName() {
    final id = getReciterId();
    // Map common reciter IDs to names
    final reciters = {
      7: 'Mishary Alafasy',
      1: 'Abdul Basit',
      2: 'Maher Al-Muaiqly',
      3: 'Saud Al-Shuraim',
    };
    return reciters[id] ?? 'Mishary Alafasy';
  }

  Future<void> setCustomAsrEndpoint(String url) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('custom_asr_endpoint', url);
  }

  String getCustomAsrEndpoint() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('whisper_model', model);
  }

  String getWhisperModel() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('whisper_model') ?? 'base';
    } catch (e) {
      Logger.warning('Failed to get whisper model: $e', feature: 'Preferences');
      return 'base';
    }
  }

  // Default Quran View: 'surah' or 'mushaf'
  Future<void> setDefaultQuranView(String view) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('default_quran_view', view);
  }

  String getDefaultQuranView() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('default_quran_view') ?? 'surah';
    } catch (e) {
      Logger.warning(
        'Failed to get default Quran view: $e',
        feature: 'Preferences',
      );
      return 'surah';
    }
  }

  Future<void> setQrcHafzLevel(int level) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setInt('qrc_hafz_level', level);
  }

  int getQrcHafzLevel() {
    try {
      _ensureInitialized();
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
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setInt('qrc_tajweed_level', level);
  }

  int getQrcTajweedLevel() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getInt('qrc_tajweed_level') ?? 3;
    } catch (e) {
      Logger.warning(
        'Failed to get qrc tajweed level: $e',
        feature: 'Preferences',
      );
      return 3;
    }
  }

  // QRC API Key (for external recitation checking service)
  Future<void> setQrcApiKey(String apiKey) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('qrc_api_key', apiKey);
  }

  String getQrcApiKey() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('qrc_api_key') ?? '';
    } catch (e) {
      Logger.warning('Failed to get QRC API key: $e', feature: 'Preferences');
      return '';
    }
  }

  // Mushaf font size multiplier (0.8 to 1.5)
  Future<void> setMushafFontSize(double size) async {
    if (_sharedPreferences == null) await init();
    // Clamp between 0.8 and 1.5
    final clampedSize = size.clamp(0.8, 1.5);
    await _sharedPreferences!.setDouble('mushaf_font_size', clampedSize);
  }

  double getMushafFontSize() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getDouble('mushaf_font_size') ?? 1.0;
    } catch (e) {
      Logger.warning(
        'Failed to get Mushaf font size: $e',
        feature: 'Preferences',
      );
      return 1.0;
    }
  }

  // Regular Quran view font size (16 to 32)
  Future<void> setRegularFontSize(double size) async {
    if (_sharedPreferences == null) await init();
    // Clamp between 16 and 32
    final clampedSize = size.clamp(16.0, 32.0);
    await _sharedPreferences!.setDouble('regular_font_size', clampedSize);
  }

  double getRegularFontSize() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getDouble('regular_font_size') ?? 22.0;
    } catch (e) {
      Logger.warning(
        'Failed to get regular font size: $e',
        feature: 'Preferences',
      );
      return 22.0;
    }
  }

  // Generic string storage
  Future<void> setString(String key, String value) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString(key, value);
  }

  String? getString(String key) {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString(key);
    } catch (e) {
      Logger.warning(
        'Failed to get string for key $key: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  // String list storage
  Future<void> setStringList(String key, List<String> value) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getStringList(key);
    } catch (e) {
      Logger.warning(
        'Failed to get string list for key $key: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  // Reading Streak Tracking
  Future<void> recordReadingSession() async {
    if (_sharedPreferences == null) await init();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastReadDate = getString('last_read_date');
    final currentStreak = getReadingStreak();

    if (lastReadDate != todayString) {
      final lastDate = _parseDate(lastReadDate);
      final todayDate = DateTime(today.year, today.month, today.day);

      if (lastDate != null) {
        final difference = todayDate.difference(lastDate).inDays;
        if (difference == 1) {
          await setInt('reading_streak', currentStreak + 1);
        } else if (difference > 1) {
          await setInt('reading_streak', 1);
        }
      } else {
        await setInt('reading_streak', 1);
      }

      await setString('last_read_date', todayString);
      await _addToReadingHistory(todayString);
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToReadingHistory(String date) async {
    final history = getStringList('reading_history') ?? [];
    if (!history.contains(date)) {
      history.add(date);
      await setStringList('reading_history', history);
    }
  }

  int getReadingStreak() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getInt('reading_streak') ?? 0;
    } catch (e) {
      Logger.warning(
        'Failed to get reading streak: $e',
        feature: 'Preferences',
      );
      return 0;
    }
  }

  int getTotalReadingDays() {
    try {
      _ensureInitialized();
      final history = _sharedPreferences!.getStringList('reading_history');
      return history?.length ?? 0;
    } catch (e) {
      Logger.warning(
        'Failed to get total reading days: $e',
        feature: 'Preferences',
      );
      return 0;
    }
  }

  List<String> getReadingHistory() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getStringList('reading_history') ?? [];
    } catch (e) {
      Logger.warning(
        'Failed to get reading history: $e',
        feature: 'Preferences',
      );
      return [];
    }
  }

  // Generic int storage
  Future<void> setInt(String key, int value) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setInt(key, value);
  }

  int? getInt(String key) {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getInt(key);
    } catch (e) {
      Logger.warning(
        'Failed to get int for key $key: $e',
        feature: 'Preferences',
      );
      return null;
    }
  }

  // Orientation preference: 'portrait', 'landscape', 'auto'
  Future<void> setOrientationMode(String mode) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('orientation_mode', mode);
  }

  String getOrientationMode() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('orientation_mode') ?? 'portrait';
    } catch (e) {
      Logger.warning(
        'Failed to get orientation mode: $e',
        feature: 'Preferences',
      );
      return 'portrait';
    }
  }

  // Reading navigation mode: 'scroll' (current), 'page' (surah-to-surah navigation)
  Future<void> setReadingNavMode(String mode) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('reading_nav_mode', mode);
  }

  String getReadingNavMode() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getString('reading_nav_mode') ?? 'scroll';
    } catch (e) {
      Logger.warning(
        'Failed to get reading nav mode: $e',
        feature: 'Preferences',
      );
      return 'scroll';
    }
  }

  // Onboarding completed flag
  Future<void> setOnboardingCompleted(bool completed) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setBool('onboarding_completed', completed);
  }

  bool getOnboardingCompleted() {
    if (_sharedPreferences == null) {
      return false;
    }
    try {
      return _sharedPreferences!.getBool('onboarding_completed') ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to get onboarding completed flag: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  // Autoscroll settings
  Future<void> setAutoScrollEnabled(bool enabled) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setBool('auto_scroll_enabled', enabled);
  }

  bool getAutoScrollEnabled() {
    if (_sharedPreferences == null) {
      return false;
    }
    try {
      return _sharedPreferences!.getBool('auto_scroll_enabled') ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to get auto scroll enabled: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }

  Future<void> setAutoScrollSpeed(double speed) async {
    if (_sharedPreferences == null) await init();
    // Clamp speed between 0.1x (very slow) and 5x (very fast)
    final clampedSpeed = speed.clamp(0.1, 5.0);
    await _sharedPreferences!.setDouble('auto_scroll_speed', clampedSpeed);
  }

  double getAutoScrollSpeed() {
    if (_sharedPreferences == null) {
      return 1.0;
    }
    try {
      return _sharedPreferences!.getDouble('auto_scroll_speed') ?? 1.0;
    } catch (e) {
      Logger.warning(
        'Failed to get auto scroll speed: $e',
        feature: 'Preferences',
      );
      return 1.0;
    }
  }

  // Selected Quran font
  Future<void> setQuranFont(String fontName) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setString('quran_font', fontName);
  }

  String getQuranFont() {
    if (_sharedPreferences == null) {
      return 'amiri';
    }
    try {
      return _sharedPreferences!.getString('quran_font') ?? 'amiri';
    } catch (e) {
      Logger.warning('Failed to get Quran font: $e', feature: 'Preferences');
      return 'amiri';
    }
  }

  // Horizontal Pagination for regular Quran view
  Future<void> setHorizontalPagination(bool isHorizontal) async {
    if (_sharedPreferences == null) await init();
    await _sharedPreferences!.setBool('horizontal_pagination', isHorizontal);
  }

  bool getHorizontalPagination() {
    try {
      _ensureInitialized();
      return _sharedPreferences!.getBool('horizontal_pagination') ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to get horizontal pagination mode: $e',
        feature: 'Preferences',
      );
      return false;
    }
  }
}

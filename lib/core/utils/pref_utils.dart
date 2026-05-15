//ignore: unused_import
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;
  static Completer<SharedPreferences>? _initCompleter;
  static String? _cachedAppVersion;

  PrefUtils() {
    init().catchError((_) {});
  }

  /// Cache the current app version for synchronous access during route setup.
  void setCachedAppVersion(String version) => _cachedAppVersion = version;

  String? getCachedAppVersion() => _cachedAppVersion;

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
      Logger.info('SharedPreference Initialized', feature: 'Preferences');
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

  // Generic accessors for dynamic keys
  Future<void> setString(String key, String value) async {
    await _requirePrefs().setString(key, value);
  }

  String? getString(String key) => _requirePrefs().getString(key);

  Future<void> setBool(String key, bool value) async {
    await _requirePrefs().setBool(key, value);
  }

  bool? getBool(String key) => _requirePrefs().getBool(key);

  Future<void> setInt(String key, int value) async {
    await _requirePrefs().setInt(key, value);
  }

  int? getInt(String key) => _requirePrefs().getInt(key);

  Future<void> remove(String key) async {
    await _requirePrefs().remove(key);
  }

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

  bool isAdaptiveQrc() {
    try {
      return _requirePrefs().getBool('adaptive_qrc') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setAdaptiveQrc(bool enabled) async {
    await _requirePrefs().setBool('adaptive_qrc', enabled);
  }

  DateTime? getQfLastSyncAt() {
    try {
      final s = _requirePrefs().getString('qf_last_sync_at');
      return s != null ? DateTime.tryParse(s) : null;
    } catch (e) {
      Logger.warning('Failed to read qf_last_sync_at: $e', feature: 'Prefs');
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

  int getMushafLastPageForType(String type) =>
      _requirePrefs().getInt('mushafLastPage_$type') ?? 1;

  Future<void> setMushafLastPageForType(String type, int page) async =>
      _requirePrefs().setInt('mushafLastPage_$type', page);

  /// Returns true if onboarding has been completed for the current app version.
  bool getOnboardingCompleted() {
    try {
      final completedVersion = _requirePrefs().getString(
        'onboardingCompletedVersion',
      );
      if (completedVersion == null) return false;
      final currentVersion = _cachedAppVersion;
      if (currentVersion == null) return completedVersion.isNotEmpty;
      return completedVersion == currentVersion;
    } catch (e) {
      return false;
    }
  }

  /// Marks onboarding as completed for the current app version.
  Future<void> setOnboardingCompleted(bool value) async {
    if (value) {
      final version = _cachedAppVersion ?? '';
      await _requirePrefs().setString('onboardingCompletedVersion', version);
      await _requirePrefs().setBool('app_first_open', false);
    } else {
      await _requirePrefs().remove('onboardingCompletedVersion');
    }
  }

  /// Returns true if this is the first time the app has ever been opened.
  bool isFirstEverOpen() {
    try {
      return _requirePrefs().getBool('app_first_open') ?? true;
    } catch (e) {
      return true;
    }
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

  String getPreferredTafsirId() {
    try {
      return _requirePrefs().getString('preferred_tafsir_id') ??
          ApiConfig.tafsirId;
    } catch (e) {
      return ApiConfig.tafsirId;
    }
  }

  Future<void> setPreferredTafsirId(String id) async {
    await _requirePrefs().setString('preferred_tafsir_id', id);
  }

  String getPreferredTranslationId() {
    try {
      return _requirePrefs().getString('preferred_translation_id') ??
          ApiConfig.translationId.toString();
    } catch (e) {
      return ApiConfig.translationId.toString();
    }
  }

  Future<void> setPreferredTranslationId(String id) async {
    await _requirePrefs().setString('preferred_translation_id', id);
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

  String getDailyVerseTime() {
    try {
      return _requirePrefs().getString('dailyVerseTime') ?? '08:00';
    } catch (e) {
      return '08:00';
    }
  }

  Future<void> setDailyVerseTime(String time) async {
    await _requirePrefs().setString('dailyVerseTime', time);
  }

  // ── Friday Surah Al-Kahf Reminder ──

  bool isFridayKahfEnabled() {
    try {
      return _requirePrefs().getBool('fridayKahfEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> setFridayKahfEnabled(bool enabled) async {
    await _requirePrefs().setBool('fridayKahfEnabled', enabled);
  }

  String getFridayKahfTime() {
    try {
      return _requirePrefs().getString('fridayKahfTime') ?? '06:00';
    } catch (e) {
      return '06:00';
    }
  }

  Future<void> setFridayKahfTime(String time) async {
    await _requirePrefs().setString('fridayKahfTime', time);
  }

  String getReadingReminderTime() {
    try {
      return _requirePrefs().getString('readingReminderTime') ?? '20:00';
    } catch (e) {
      return '20:00';
    }
  }

  Future<void> setReadingReminderTime(String time) async {
    await _requirePrefs().setString('readingReminderTime', time);
  }

  // ── User Archetype & Surface ──

  String? getUserArchetype() {
    try {
      return _requirePrefs().getString('userArchetype');
    } catch (e) {
      return null;
    }
  }

  Future<void> setUserArchetype(String archetype) async {
    await _requirePrefs().setString('userArchetype', archetype);
  }

  String? getSurfaceType() {
    try {
      return _requirePrefs().getString('surfaceType');
    } catch (e) {
      return null;
    }
  }

  Future<void> setSurfaceType(String surface) async {
    await _requirePrefs().setString('surfaceType', surface);
  }

  // Recent Search History
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  List<String> getRecentSearches() {
    try {
      final jsonStr = _requirePrefs().getString(_recentSearchesKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>?;
      return list?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final searches = getRecentSearches();
    searches.remove(query.trim());
    searches.insert(0, query.trim());
    while (searches.length > _maxRecentSearches) {
      searches.removeLast();
    }
    await _requirePrefs().setString(_recentSearchesKey, jsonEncode(searches));
  }

  Future<void> clearRecentSearches() async {
    await _requirePrefs().remove(_recentSearchesKey);
  }

  // ── Audio Playback Position ──

  /// Returns the last played verse index (0-based) for a given surah, or null.
  int? getLastAudioVerse(int surahId) {
    try {
      return _requirePrefs().getInt('last_audio_verse_$surahId');
    } catch (e) {
      Logger.warning('Failed to read last audio verse: $e', feature: 'Prefs');
      return null;
    }
  }

  Future<void> setLastAudioVerse(int surahId, int verseIndex) async {
    await _requirePrefs().setInt('last_audio_verse_$surahId', verseIndex);
  }

  // ── QF Preference Sync Tracking ──

  static const String _qfPrefSyncPromptedKey = 'qf_pref_sync_prompted';
  static const String _qfPrefSyncDirectionKey = 'qf_pref_sync_direction';

  /// Whether the user has already been prompted to sync preferences on login.
  bool getQfPrefSyncPrompted() {
    try {
      return _requirePrefs().getBool(_qfPrefSyncPromptedKey) ?? false;
    } catch (e) {
      Logger.warning('Failed to read QF pref sync prompted: $e', feature: 'Prefs');
      return false;
    }
  }

  Future<void> setQfPrefSyncPrompted(bool value) async {
    await _requirePrefs().setBool(_qfPrefSyncPromptedKey, value);
  }

  /// The last chosen sync direction: 'pull' (QF → local), 'push' (local → QF), or null.
  String? getQfPrefSyncDirection() {
    try {
      return _requirePrefs().getString(_qfPrefSyncDirectionKey);
    } catch (e) {
      Logger.warning('Failed to read QF pref sync direction: $e', feature: 'Prefs');
      return null;
    }
  }

  Future<void> setQfPrefSyncDirection(String? direction) async {
    if (direction == null) {
      await _requirePrefs().remove(_qfPrefSyncDirectionKey);
    } else {
      await _requirePrefs().setString(_qfPrefSyncDirectionKey, direction);
    }
  }

  // ── Widget Promo ──

  static const String _widgetPromoDismissedKey = 'widget_promo_dismissed';

  bool hasDismissedWidgetPromo() {
    try {
      return _requirePrefs().getBool(_widgetPromoDismissedKey) ?? false;
    } catch (e) {
      Logger.warning('Failed to read widget promo dismissed: $e', feature: 'Prefs');
      return false;
    }
  }

  Future<void> dismissWidgetPromo() async {
    await _requirePrefs().setBool(_widgetPromoDismissedKey, true);
  }

  // ── Notification Preferences ──

  static const String _readingReminderEnabledKey = 'reading_reminder_enabled';

  bool isReadingReminderEnabled() {
    try {
      return _requirePrefs().getBool(_readingReminderEnabledKey) ?? true;
    } catch (e) {
      Logger.warning(
        'Failed to get reading reminder enabled: $e',
        feature: 'Preferences',
      );
      return true;
    }
  }

  Future<void> setReadingReminderEnabled(bool value) async {
    await _requirePrefs().setBool(_readingReminderEnabledKey, value);
  }

  static const String _keepScreenOnKey = 'keep_screen_on';

  bool isKeepScreenOn() {
    try {
      return _requirePrefs().getBool(_keepScreenOnKey) ?? true;
    } catch (e) {
      Logger.warning(
        'Failed to get keep screen on: $e',
        feature: 'Preferences',
      );
      return true;
    }
  }

  Future<void> setKeepScreenOn(bool value) async {
    await _requirePrefs().setBool(_keepScreenOnKey, value);
  }

  // ── Goal Celebration ──

  static const String _lastCelebratedDateKey = 'last_celebrated_date';

  String? getLastCelebratedDate() {
    try {
      return _requirePrefs().getString(_lastCelebratedDateKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastCelebratedDate(String date) async {
    await _requirePrefs().setString(_lastCelebratedDateKey, date);
  }

  static const String _lastStreakCelebratedKey = 'last_streak_celebrated';

  int? getLastStreakCelebrated() {
    try {
      return _requirePrefs().getInt(_lastStreakCelebratedKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastStreakCelebrated(int milestone) async {
    await _requirePrefs().setInt(_lastStreakCelebratedKey, milestone);
  }
}

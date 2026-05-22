//ignore: unused_import
import 'dart:async';
import 'dart:convert';

import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences/milestone_preferences.dart';
import 'preferences/notification_preferences.dart';
import 'preferences/onboarding_preferences.dart';
import 'preferences/reading_preferences.dart';
import 'preferences/sync_preferences.dart';
import 'preferences/theme_preferences.dart';
import 'preferences/translation_preferences.dart';
import 'preferences/voice_preferences.dart';

/// Central preferences facade.
///
/// All domain-specific preferences have been extracted into focused classes
/// under [preferences/]. [PrefUtils] keeps the original API surface so
/// existing call-sites continue to work without modification.
class PrefUtils {
  static SharedPreferences? _sharedPreferences;
  static Completer<SharedPreferences>? _initCompleter;
  static String? _cachedAppVersion;

  // Domain-specific preference instances (lazy, stateless)
  static final ThemePreferences _theme = ThemePreferences();
  static final ReadingPreferences _reading = ReadingPreferences();
  static final TranslationPreferences _translation = TranslationPreferences();
  static final VoicePreferences _voice = VoicePreferences();
  static final SyncPreferences _sync = SyncPreferences();
  static final NotificationPreferences _notification =
      NotificationPreferences();
  static final MilestonePreferences _milestone = MilestonePreferences();
  static final OnboardingPreferences _onboarding = OnboardingPreferences();

  /// Direct access to the underlying [SharedPreferences] instance.
  static SharedPreferences get prefs {
    if (_sharedPreferences != null) return _sharedPreferences!;
    throw StateError(
      'PrefUtils: SharedPreferences accessed before init() completed. '
      'Ensure PrefUtils.init() is awaited before reading preferences.',
    );
  }

  PrefUtils() {
    init().catchError((_) {});
  }

  /// Cache the current app version for synchronous access during route setup.
  void setCachedAppVersion(String version) => _cachedAppVersion = version;

  String? getCachedAppVersion() => _cachedAppVersion;

  static String? get cachedAppVersion => _cachedAppVersion;

  static bool get isInitialized => _sharedPreferences != null;

  /// Initialise SharedPreferences. Safe to call multiple times; concurrent
  /// callers will coalesce on the same Completer.
  Future<void> init() async {
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<SharedPreferences>();
    try {
      final p = await SharedPreferences.getInstance();
      _sharedPreferences = p;
      _initCompleter!.complete(p);
      Logger.info('SharedPreference Initialized', feature: 'Preferences');
    } catch (e) {
      _initCompleter = null;
      rethrow;
    }
  }

  /// Ensures [_sharedPreferences] is available.
  SharedPreferences _requirePrefs() {
    if (_sharedPreferences != null) return _sharedPreferences!;
    throw StateError(
      'PrefUtils: SharedPreferences accessed before init() completed. '
      'Ensure PrefUtils.init() is awaited before reading preferences.',
    );
  }

  /// Will clear all the data stored in preference.
  Future<void> clearPreferencesData() async {
    await _requirePrefs().clear();
  }

  // ── Generic accessors for dynamic keys ──

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

  // ═══════════════════════════════════════════════════════════════
  //  Facade methods – delegate to domain-specific preference classes
  // ═══════════════════════════════════════════════════════════════

  // ── Locale ──
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

  // ── Theme ──
  Future<void> setThemeMode(String mode) => _theme.setThemeMode(mode);
  String getThemeMode() => _theme.getThemeMode();
  bool getIsDarkMode() => _theme.getIsDarkMode();
  Future<void> setIsDarkMode(bool value) => _theme.setIsDarkMode(value);

  // ── Onboarding / Version ──
  String? getLastRunVersion() => _onboarding.getLastRunVersion();
  void setLastRunVersion(String version) => _onboarding.setLastRunVersion(version);
  bool getOnboardingCompleted() => _onboarding.getOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool value) =>
      _onboarding.setOnboardingCompleted(value);
  bool getHifzMigrationCompleted() => _onboarding.getHifzMigrationCompleted();
  Future<void> setHifzMigrationCompleted(bool value) =>
      _onboarding.setHifzMigrationCompleted(value);
  int getOnboardingStep() => _onboarding.getOnboardingStep();
  Future<void> setOnboardingStep(int step) => _onboarding.setOnboardingStep(step);
  bool isFirstEverOpen() => _onboarding.isFirstEverOpen();

  // ── Reading ──
  Future<void> setSurahOffset(int surahId, double offset) =>
      _reading.setSurahOffset(surahId, offset);
  double? getSurahOffset(int surahId) => _reading.getSurahOffset(surahId);
  Future<void> setSurahVerseIndex(int surahId, int index) =>
      _reading.setSurahVerseIndex(surahId, index);
  int? getSurahVerseIndex(int surahId) => _reading.getSurahVerseIndex(surahId);
  Future<void> setVerseViewMode(bool isSingleLine) =>
      _reading.setVerseViewMode(isSingleLine);
  bool getVerseViewMode() => _reading.getVerseViewMode();
  double getQuranFontSize() => _reading.getQuranFontSize();
  Future<void> setQuranFontSize(double size) => _reading.setQuranFontSize(size);
  String getOrientationMode() => _reading.getOrientationMode();
  Future<void> setOrientationMode(String mode) =>
      _reading.setOrientationMode(mode);
  String getDefaultQuranView() => _reading.getDefaultQuranView();
  Future<void> setDefaultQuranView(String view) =>
      _reading.setDefaultQuranView(view);
  String getReadingNavMode() => _reading.getReadingNavMode();
  Future<void> setReadingNavMode(String mode) =>
      _reading.setReadingNavMode(mode);
  String? getMushafType() => _reading.getMushafType();
  Future<void> setMushafType(String type) => _reading.setMushafType(type);
  int getMushafLastPage() => _reading.getMushafLastPage();
  Future<void> setMushafLastPage(int page) => _reading.setMushafLastPage(page);
  int getMushafLastPageForType(String type) =>
      _reading.getMushafLastPageForType(type);
  Future<void> setMushafLastPageForType(String type, int page) =>
      _reading.setMushafLastPageForType(type, page);
  bool isKeepScreenOn() => _reading.isKeepScreenOn();
  Future<void> setKeepScreenOn(bool value) => _reading.setKeepScreenOn(value);
  Future<void> saveLastReadSurah(Surah surah) =>
      _reading.saveLastReadSurah(surah);
  Surah? getLastReadSurah() => _reading.getLastReadSurah();

  // ── Translation ──
  bool getShowTranslation() => _translation.getShowTranslation();
  Future<void> setShowTranslation(bool value) =>
      _translation.setShowTranslation(value);
  String getPreferredTafsirId() => _translation.getPreferredTafsirId();
  Future<void> setPreferredTafsirId(String id) =>
      _translation.setPreferredTafsirId(id);
  String getPreferredTranslationId() => _translation.getPreferredTranslationId();
  Future<void> setPreferredTranslationId(String id) =>
      _translation.setPreferredTranslationId(id);

  // ── Voice / Recitation ──
  Future<void> setRecitationProvider(String provider) =>
      _voice.setRecitationProvider(provider);
  String getRecitationProvider() => _voice.getRecitationProvider();
  Future<void> setQiraatEdition(String edition) =>
      _voice.setQiraatEdition(edition);
  String getQiraatEdition() => _voice.getQiraatEdition();
  Future<void> setReciterId(int id) => _voice.setReciterId(id);
  int getReciterId() => _voice.getReciterId();
  Future<void> setCustomAsrEndpoint(String url) =>
      _voice.setCustomAsrEndpoint(url);
  String getCustomAsrEndpoint() => _voice.getCustomAsrEndpoint();
  Future<void> setWhisperModel(String model) => _voice.setWhisperModel(model);
  String getWhisperModel() => _voice.getWhisperModel();
  Future<void> setQrcHafzLevel(int level) => _voice.setQrcHafzLevel(level);
  int getQrcHafzLevel() => _voice.getQrcHafzLevel();
  Future<void> setQrcTajweedLevel(int level) =>
      _voice.setQrcTajweedLevel(level);
  int getQrcTajweedLevel() => _voice.getQrcTajweedLevel();
  bool isAdaptiveQrc() => _voice.isAdaptiveQrc();
  Future<void> setAdaptiveQrc(bool enabled) => _voice.setAdaptiveQrc(enabled);

  // ── Sync ──
  DateTime? getQfLastSyncAt() => _sync.getQfLastSyncAt();
  Future<void> setQfLastSyncAt(DateTime dt) => _sync.setQfLastSyncAt(dt);
  String? getBookmarkCollectionId() => _sync.getBookmarkCollectionId();
  Future<void> setBookmarkCollectionId(String id) =>
      _sync.setBookmarkCollectionId(id);
  bool getQfPrefSyncPrompted() => _sync.getQfPrefSyncPrompted();
  Future<void> setQfPrefSyncPrompted(bool value) =>
      _sync.setQfPrefSyncPrompted(value);
  String? getQfPrefSyncDirection() => _sync.getQfPrefSyncDirection();
  Future<void> setQfPrefSyncDirection(String? direction) =>
      _sync.setQfPrefSyncDirection(direction);
  Future<void> recordDeletedBookmark(int surahId, int verseNumber) =>
      _sync.recordDeletedBookmark(surahId, verseNumber);
  bool isRecentlyDeletedBookmark(
    int surahId,
    int verseNumber, {
    Duration within = const Duration(hours: 24),
  }) =>
      _sync.isRecentlyDeletedBookmark(surahId, verseNumber, within: within);
  Future<void> clearRecentlyDeletedBookmarks() =>
      _sync.clearRecentlyDeletedBookmarks();

  // ── Notification ──
  bool isDailyVerseEnabled() => _notification.isDailyVerseEnabled();
  Future<void> setDailyVerseEnabled(bool enabled) =>
      _notification.setDailyVerseEnabled(enabled);
  String getDailyVerseTime() => _notification.getDailyVerseTime();
  Future<void> setDailyVerseTime(String time) =>
      _notification.setDailyVerseTime(time);
  bool isFridayKahfEnabled() => _notification.isFridayKahfEnabled();
  Future<void> setFridayKahfEnabled(bool enabled) =>
      _notification.setFridayKahfEnabled(enabled);
  String getFridayKahfTime() => _notification.getFridayKahfTime();
  Future<void> setFridayKahfTime(String time) =>
      _notification.setFridayKahfTime(time);
  bool isReadingReminderEnabled() => _notification.isReadingReminderEnabled();
  Future<void> setReadingReminderEnabled(bool value) =>
      _notification.setReadingReminderEnabled(value);
  String getReadingReminderTime() => _notification.getReadingReminderTime();
  Future<void> setReadingReminderTime(String time) =>
      _notification.setReadingReminderTime(time);

  // ── Milestones ──
  String? getLastCelebratedDate() => _milestone.getLastCelebratedDate();
  Future<void> setLastCelebratedDate(String date) =>
      _milestone.setLastCelebratedDate(date);
  int? getLastStreakCelebrated() => _milestone.getLastStreakCelebrated();
  Future<void> setLastStreakCelebrated(int milestone) =>
      _milestone.setLastStreakCelebrated(milestone);
  int getTotalVersesRead() => _milestone.getTotalVersesRead();
  Future<void> setTotalVersesRead(int value) =>
      _milestone.setTotalVersesRead(value);
  int getKhatmahCompletionsCount() => _milestone.getKhatmahCompletionsCount();
  Future<void> setKhatmahCompletionsCount(int value) =>
      _milestone.setKhatmahCompletionsCount(value);
  bool shouldShowDuaKhatm() => _milestone.shouldShowDuaKhatm();
  Future<void> setShouldShowDuaKhatm(bool value) =>
      _milestone.setShouldShowDuaKhatm(value);

  // ── User Archetype & Surface (kept in facade) ──
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

  // ── Recent Search History (kept in facade) ──
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

  // ── Audio Playback Position (kept in facade) ──
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

  // ── Widget Promo (kept in facade) ──
  static const String _widgetPromoDismissedKey = 'widget_promo_dismissed';

  bool hasDismissedWidgetPromo() {
    try {
      return _requirePrefs().getBool(_widgetPromoDismissedKey) ?? false;
    } catch (e) {
      Logger.warning(
        'Failed to read widget promo dismissed: $e',
        feature: 'Prefs',
      );
      return false;
    }
  }

  Future<void> dismissWidgetPromo() async {
    await _requirePrefs().setBool(_widgetPromoDismissedKey, true);
  }
}

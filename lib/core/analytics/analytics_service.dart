import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hafiz_app/core/utils/logger.dart';

import 'analytics_events.dart';
import 'analytics_properties.dart';

/// Central analytics service wrapping Firebase Analytics.
///
/// All event names and parameter keys are defined in [AnalyticsEvents]
/// and [AnalyticsParams] to prevent typos and enable IDE autocomplete.
///
/// Usage:
/// ```dart
/// sl<AnalyticsService>().logOpenSurah(1);
/// ```
class AnalyticsService {
  AnalyticsService();

  FirebaseAnalytics? _cached;
  bool _checked = false;

  FirebaseAnalytics? get _analytics {
    if (_checked) return _cached;
    _checked = true;
    try {
      if (Firebase.apps.isEmpty) return null;
      _cached = FirebaseAnalytics.instance;
      return _cached;
    } catch (e) {
      Logger.warning('Analytics initialization failed: $e', feature: 'Analytics');
      return null;
    }
  }

  // ── Screen Timing ──

  final Map<String, DateTime> _screenEnter = {};

  void startScreenTimer(String name) {
    _screenEnter[name] = DateTime.now();
  }

  Future<void> endScreenTimer(String name) async {
    final start = _screenEnter.remove(name);
    if (start != null) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      await _logEvent(
        AnalyticsEvents.screenTime,
        parameters: {AnalyticsParams.screenName: name, AnalyticsParams.durationMs: ms},
      );
    }
  }

  // ── User Properties ──

  Future<void> setUserProperty({required String name, required String? value}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.setUserProperty(name: name, value: value);
    } catch (e) {
      Logger.warning('Set user property failed: $e', feature: 'Analytics');
    }
  }

  Future<void> setUserId(String? userId) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.setUserId(id: userId);
    } catch (e) {
      Logger.warning('Set user id failed: $e', feature: 'Analytics');
    }
  }

  /// Batch-set common user properties based on current app state.
  Future<void> setCoreUserProperties({
    String? archetype,
    String? locale,
    String? themeMode,
    bool? isQfLoggedIn,
    String? dominantAction,
    bool? showTranslation,
    String? mushafType,
    String? reciterId,
    bool? onboardingCompleted,
    int? bookmarkCount,
    bool? hasActiveKhatmah,
    int? memorizedVerses,
  }) async {
    if (archetype != null) {
      await setUserProperty(name: AnalyticsProperties.archetype, value: archetype);
    }
    if (locale != null) {
      await setUserProperty(name: AnalyticsProperties.locale, value: locale);
    }
    if (themeMode != null) {
      await setUserProperty(name: AnalyticsProperties.themeMode, value: themeMode);
    }
    if (isQfLoggedIn != null) {
      await setUserProperty(
        name: AnalyticsProperties.isQfLoggedIn,
        value: isQfLoggedIn.toString(),
      );
    }
    if (dominantAction != null) {
      await setUserProperty(
        name: AnalyticsProperties.dominantAction,
        value: dominantAction,
      );
    }
    if (showTranslation != null) {
      await setUserProperty(
        name: AnalyticsProperties.showTranslation,
        value: showTranslation.toString(),
      );
    }
    if (mushafType != null) {
      await setUserProperty(name: AnalyticsProperties.mushafType, value: mushafType);
    }
    if (reciterId != null) {
      await setUserProperty(name: AnalyticsProperties.reciterId, value: reciterId);
    }
    if (onboardingCompleted != null) {
      await setUserProperty(
        name: AnalyticsProperties.onboardingCompleted,
        value: onboardingCompleted.toString(),
      );
    }
    if (bookmarkCount != null) {
      await setUserProperty(
        name: AnalyticsProperties.bookmarkCount,
        value: bookmarkCount.toString(),
      );
    }
    if (hasActiveKhatmah != null) {
      await setUserProperty(
        name: AnalyticsProperties.hasActiveKhatmah,
        value: hasActiveKhatmah.toString(),
      );
    }
    if (memorizedVerses != null) {
      await setUserProperty(
        name: AnalyticsProperties.memorizedVerses,
        value: memorizedVerses.toString(),
      );
    }
  }

  // ── Generic Event Helper ──

  /// Public raw event logger for internal observers and wrappers.
  Future<void> logRawEvent(String name, {Map<String, Object>? parameters}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logEvent(name: name, parameters: parameters);
    } catch (e) {
      Logger.warning('Analytics event failed: $e', feature: 'Analytics');
    }
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await logRawEvent(name, parameters: parameters);
  }

  // ── App Lifecycle ──

  Future<void> logAppOpen() => _logEvent(AnalyticsEvents.appOpen);

  Future<void> logAppBackground() => _logEvent(AnalyticsEvents.appBackground);

  Future<void> logAppForeground() => _logEvent(AnalyticsEvents.appForeground);

  // ── Screen Navigation ──

  Future<void> logScreenView({required String name, String? className}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logScreenView(screenName: name, screenClass: className);
    } catch (e) {
      Logger.warning('Screen view failed: $e', feature: 'Analytics');
    }
  }

  // ── User Preferences ──

  Future<void> logLanguageChange(String code) => _logEvent(
    AnalyticsEvents.languageChange,
    parameters: {AnalyticsParams.code: code},
  );

  Future<void> logThemeChange(bool isDark) => _logEvent(
    AnalyticsEvents.themeToggle,
    parameters: {AnalyticsParams.isDark: isDark ? 1 : 0},
  );

  // ── Onboarding ──

  Future<void> logOnboardingStarted() => _logEvent(AnalyticsEvents.onboardingStarted);

  Future<void> logOnboardingCompleted() => _logEvent(AnalyticsEvents.onboardingCompleted);

  Future<void> logOnboardingStepViewed({required int step, required int totalSteps}) =>
      _logEvent(
        AnalyticsEvents.onboardingStepViewed,
        parameters: {AnalyticsParams.step: step, AnalyticsParams.totalSteps: totalSteps},
      );

  Future<void> logOnboardingSkipped({required int atStep}) => _logEvent(
    AnalyticsEvents.onboardingSkipped,
    parameters: {AnalyticsParams.step: atStep},
  );

  Future<void> logArchetypeSelected(String archetype) => _logEvent(
    AnalyticsEvents.archetypeSelected,
    parameters: {AnalyticsParams.archetype: archetype},
  );

  // ── Reading ──

  Future<void> logOpenSurah(int surahId) => _logEvent(
    AnalyticsEvents.openSurah,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logOpenMushaf(int page) => _logEvent(
    AnalyticsEvents.openMushaf,
    parameters: {AnalyticsParams.offset: page},
  );

  Future<void> logContinueReading(int surahId, double? offset) => _logEvent(
    AnalyticsEvents.continueReading,
    parameters: {
      AnalyticsParams.surahId: surahId,
      AnalyticsParams.offset: offset ?? 0.0,
    },
  );

  Future<void> logReadingSession({
    required int chapterNumber,
    required int versesRead,
    int? durationSeconds,
  }) =>
      _logEvent(
        AnalyticsEvents.readingSession,
        parameters: {
          AnalyticsParams.chapterNumber: chapterNumber,
          AnalyticsParams.versesRead: versesRead,
          AnalyticsParams.durationSeconds: ?durationSeconds,
        },
      );

  Future<void> logVerseTapped({required int surahId, required int verseNumber}) => _logEvent(
    AnalyticsEvents.verseTapped,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.verseNumber: verseNumber},
  );

  Future<void> logTafsirOpened({required int surahId, required int verseNumber, String? source}) =>
      _logEvent(
        AnalyticsEvents.tafsirOpened,
        parameters: {
          AnalyticsParams.surahId: surahId,
          AnalyticsParams.verseNumber: verseNumber,
          AnalyticsParams.tafsirSource: ?source,
        },
      );

  Future<void> logTafsirSourceChanged(String source) => _logEvent(
    AnalyticsEvents.tafsirSourceChanged,
    parameters: {AnalyticsParams.tafsirSource: source},
  );

  Future<void> logTranslationToggled(bool shown) => _logEvent(
    AnalyticsEvents.translationToggled,
    parameters: {AnalyticsParams.showTranslation: shown},
  );

  Future<void> logAutoScrollToggled(bool enabled) => _logEvent(
    AnalyticsEvents.autoScrollToggled,
    parameters: {AnalyticsParams.enabled: enabled},
  );

  Future<void> logListeningModeToggled(bool enabled) => _logEvent(
    AnalyticsEvents.listeningModeToggled,
    parameters: {AnalyticsParams.enabled: enabled},
  );

  // ── Audio ──

  Future<void> logAudioPlay({required int surahId, int? verseNumber, String? reciterId}) =>
      _logEvent(
        AnalyticsEvents.audioPlay,
        parameters: {
          AnalyticsParams.surahId: surahId,
          AnalyticsParams.verseNumber: ?verseNumber,
          AnalyticsParams.reciterId: ?reciterId,
        },
      );

  Future<void> logAudioPause({required int surahId}) => _logEvent(
    AnalyticsEvents.audioPause,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logAudioStop({required int surahId}) => _logEvent(
    AnalyticsEvents.audioStop,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logAudioCompleted({required int surahId}) => _logEvent(
    AnalyticsEvents.audioCompleted,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logAudioSpeedChanged(double speed) => _logEvent(
    AnalyticsEvents.audioSpeedChanged,
    parameters: {AnalyticsParams.speed: speed},
  );

  Future<void> logReciterChanged(String reciterId) => _logEvent(
    AnalyticsEvents.reciterChanged,
    parameters: {AnalyticsParams.reciterId: reciterId},
  );

  Future<void> logSleepTimerSet(int minutes) => _logEvent(
    AnalyticsEvents.sleepTimerSet,
    parameters: {AnalyticsParams.timerMinutes: minutes},
  );

  Future<void> logAudioError({required String message}) => _logEvent(
    AnalyticsEvents.audioError,
    parameters: {AnalyticsParams.errorMessage: message},
  );

  // ── Memorization / Hifz ──

  Future<void> logHifzModeToggled(bool enabled) => _logEvent(
    AnalyticsEvents.hifzModeToggled,
    parameters: {AnalyticsParams.enabled: enabled},
  );

  Future<void> logVerseRevealed({required int surahId, required int verseNumber}) => _logEvent(
    AnalyticsEvents.verseRevealed,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.verseNumber: verseNumber},
  );

  Future<void> logReviewStarted({required int surahId}) => _logEvent(
    AnalyticsEvents.reviewStarted,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logReviewCompleted({required int surahId, required int score}) => _logEvent(
    AnalyticsEvents.reviewCompleted,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.score: score},
  );

  Future<void> logMemorizationProgressViewed() => _logEvent(
    AnalyticsEvents.memorizationProgressViewed,
  );

  Future<void> logHelpOpened({required String feature}) => _logEvent(
    AnalyticsEvents.helpOpened,
    parameters: {AnalyticsParams.source: feature},
  );

  // ── Voice Recitation / QRC ──

  Future<void> logRecitationStarted({required int surahId}) => _logEvent(
    AnalyticsEvents.recitationStarted,
    parameters: {AnalyticsParams.surahId: surahId},
  );

  Future<void> logRecitationVerified({required int surahId, required double accuracy}) => _logEvent(
    AnalyticsEvents.recitationVerified,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.accuracy: accuracy},
  );

  Future<void> logRecitationErrorReported({required int surahId, required int verseNumber}) =>
      _logEvent(
        AnalyticsEvents.recitationErrorReported,
        parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.verseNumber: verseNumber},
      );

  // ── Bookmarks ──

  Future<void> logBookmarkAdded({required int surahId, required int verseNumber}) => _logEvent(
    AnalyticsEvents.bookmarkAdded,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.verseNumber: verseNumber},
  );

  Future<void> logBookmarkRemoved({required int surahId, required int verseNumber}) => _logEvent(
    AnalyticsEvents.bookmarkRemoved,
    parameters: {AnalyticsParams.surahId: surahId, AnalyticsParams.verseNumber: verseNumber},
  );

  Future<void> logBookmarksViewed() => _logEvent(AnalyticsEvents.bookmarksViewed);

  // ── Search ──

  Future<void> logSearch(String query) => _logEvent(
    AnalyticsEvents.search,
    parameters: {AnalyticsParams.query: query},
  );

  Future<void> logSearchResultTapped({
    required String query,
    required String resultType,
    required int resultIndex,
  }) =>
      _logEvent(
        AnalyticsEvents.searchResultTapped,
        parameters: {
          AnalyticsParams.query: query,
          AnalyticsParams.resultType: resultType,
          AnalyticsParams.resultIndex: resultIndex,
        },
      );

  Future<void> logSearchEmpty(String query) => _logEvent(
    AnalyticsEvents.searchEmpty,
    parameters: {AnalyticsParams.query: query},
  );

  // ── Quran Reflect ──

  Future<void> logReflectFeedViewed() => _logEvent(AnalyticsEvents.reflectFeedViewed);

  Future<void> logReflectPostTapped(String postId) => _logEvent(
    AnalyticsEvents.reflectPostTapped,
    parameters: {AnalyticsParams.postId: postId},
  );

  // ── Verse Media ──

  Future<void> logVerseMediaViewed(int verseId) => _logEvent(
    AnalyticsEvents.verseMediaViewed,
    parameters: {AnalyticsParams.verseNumber: verseId},
  );

  // ── Goals & Khatmah ──

  Future<void> logGoalUpdated(String goalId) => _logEvent(
    AnalyticsEvents.goalUpdated,
    parameters: {AnalyticsParams.goalId: goalId},
  );

  Future<void> logGoalDeleted(String goalId) => _logEvent(
    AnalyticsEvents.goalDeleted,
    parameters: {AnalyticsParams.goalId: goalId},
  );

  Future<void> logKhatmahCreated() => _logEvent(AnalyticsEvents.khatmahCreated);

  Future<void> logKhatmahCompleted() => _logEvent(AnalyticsEvents.khatmahCompleted);

  // ── Cloud Sync ──

  Future<void> logCloudSync({required int pushed, required int pulled}) => _logEvent(
    AnalyticsEvents.cloudSync,
    parameters: {AnalyticsParams.pushed: pushed, AnalyticsParams.pulled: pulled},
  );

  Future<void> logPreferenceSync({required String direction, required int count}) => _logEvent(
    AnalyticsEvents.preferenceSync,
    parameters: {AnalyticsParams.direction: direction, AnalyticsParams.count: count},
  );

  // ── Quran.Foundation OAuth2 ──

  Future<void> logQfLogin({String? userId}) => _logEvent(
    AnalyticsEvents.qfLogin,
    parameters: userId != null ? {AnalyticsParams.userIdHash: userId.hashCode} : {},
  );

  Future<void> logQfLogout() => _logEvent(AnalyticsEvents.qfLogout);

  // ── Feedback & Links ──

  Future<void> logFeedbackSubmitted({required String method}) => _logEvent(
    AnalyticsEvents.feedbackSubmitted,
    parameters: {AnalyticsParams.method: method},
  );

  Future<void> logLinkOpened(String url) => _logEvent(
    AnalyticsEvents.openLink,
    parameters: {AnalyticsParams.url: url},
  );

  // ── Errors ──

  Future<void> logApiError({
    required String endpoint,
    int? statusCode,
    String? message,
  }) =>
      _logEvent(
        AnalyticsEvents.apiError,
        parameters: {
          AnalyticsParams.endpoint: endpoint,
          AnalyticsParams.statusCode: ?statusCode,
          AnalyticsParams.errorMessage: ?message,
        },
      );

  Future<void> logSyncFailed({required String direction, String? message}) => _logEvent(
    AnalyticsEvents.syncFailed,
    parameters: {
      AnalyticsParams.direction: direction,
      AnalyticsParams.errorMessage: ?message,
    },
  );

  Future<void> logUnexpectedError({required String feature, String? message}) => _logEvent(
    AnalyticsEvents.unexpectedError,
    parameters: {
      AnalyticsParams.source: feature,
      AnalyticsParams.errorMessage: ?message,
    },
  );

  // ── Notifications ──

  Future<void> logNotificationReceived({required String type}) => _logEvent(
    AnalyticsEvents.notificationReceived,
    parameters: {AnalyticsParams.notificationType: type},
  );

  Future<void> logNotificationTapped({required String type}) => _logEvent(
    AnalyticsEvents.notificationTapped,
    parameters: {AnalyticsParams.notificationType: type},
  );

  // ── Deep Links ──

  Future<void> logDeepLinkOpened(String url) => _logEvent(
    AnalyticsEvents.deepLinkOpened,
    parameters: {AnalyticsParams.deepLinkUrl: url},
  );

  // ── Behavior ──

  Future<void> logBehaviorSessionRecorded(String action) => _logEvent(
    AnalyticsEvents.behaviorSessionRecorded,
    parameters: {AnalyticsParams.action: action},
  );

  Future<void> logDominantActionDetected(String action) => _logEvent(
    AnalyticsEvents.dominantActionDetected,
    parameters: {AnalyticsParams.action: action},
  );
}

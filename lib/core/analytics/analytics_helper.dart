import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

/// Helper class for consistent analytics tracking
class AnalyticsHelper {
  final FirebaseAnalytics _analytics;

  AnalyticsHelper(this._analytics);

  // Screen Views
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      Logger.debug('Screen view: $screenName', feature: 'Analytics');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to log screen view',
        feature: 'Analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Surah Actions
  Future<void> logSurahOpened(int surahId, String surahName) async {
    await _logEvent('surah_opened', {
      'surah_id': surahId,
      'surah_name': surahName,
    });
  }

  Future<void> logSurahCompleted(int surahId, String surahName) async {
    await _logEvent('surah_completed', {
      'surah_id': surahId,
      'surah_name': surahName,
    });
  }

  // Bookmark Actions
  Future<void> logBookmarkAdded(int surahId, int verseNumber) async {
    await _logEvent('bookmark_added', {
      'surah_id': surahId,
      'verse_number': verseNumber,
    });
  }

  Future<void> logBookmarkRemoved(int surahId, int verseNumber) async {
    await _logEvent('bookmark_removed', {
      'surah_id': surahId,
      'verse_number': verseNumber,
    });
  }

  // Audio Actions
  Future<void> logAudioPlayed(int surahId, String reciter) async {
    await _logEvent('audio_played', {'surah_id': surahId, 'reciter': reciter});
  }

  Future<void> logAudioPaused(int surahId, int position) async {
    await _logEvent('audio_paused', {
      'surah_id': surahId,
      'position_seconds': position,
    });
  }

  Future<void> logAudioCompleted(int surahId) async {
    await _logEvent('audio_completed', {'surah_id': surahId});
  }

  Future<void> logPlaybackSpeedChanged(double speed) async {
    await _logEvent('playback_speed_changed', {'speed': speed});
  }

  Future<void> logSleepTimerSet(int minutes) async {
    await _logEvent('sleep_timer_set', {'minutes': minutes});
  }

  // Search Actions
  Future<void> logSearchPerformed(String query, int resultCount) async {
    await _logEvent('search_performed', {
      'query_length': query.length,
      'result_count': resultCount,
    });
  }

  Future<void> logSearchResultTapped(int surahId, int verseNumber) async {
    await _logEvent('search_result_tapped', {
      'surah_id': surahId,
      'verse_number': verseNumber,
    });
  }

  // Recitation Actions
  Future<void> logRecitationStarted(int surahId, int verseNumber) async {
    await _logEvent('recitation_started', {
      'surah_id': surahId,
      'verse_number': verseNumber,
    });
  }

  Future<void> logRecitationCompleted(
    int surahId,
    int verseNumber,
    bool hasErrors,
  ) async {
    await _logEvent('recitation_completed', {
      'surah_id': surahId,
      'verse_number': verseNumber,
      'has_errors': hasErrors,
    });
  }

  Future<void> logRecitationError(
    int surahId,
    int verseNumber,
    String errorType,
  ) async {
    await _logEvent('recitation_error', {
      'surah_id': surahId,
      'verse_number': verseNumber,
      'error_type': errorType,
    });
  }

  // Settings Actions
  Future<void> logThemeChanged(String themeMode) async {
    await _logEvent('theme_changed', {'theme_mode': themeMode});
  }

  Future<void> logLanguageChanged(String languageCode) async {
    await _logEvent('language_changed', {'language_code': languageCode});
  }

  Future<void> logMushafTypeChanged(String mushafType) async {
    await _logEvent('mushaf_type_changed', {'mushaf_type': mushafType});
  }

  Future<void> logReciterChanged(int reciterId, String reciterName) async {
    await _logEvent('reciter_changed', {
      'reciter_id': reciterId,
      'reciter_name': reciterName,
    });
  }

  // Sharing Actions
  Future<void> logVerseShared(
    int surahId,
    int verseNumber,
    String method,
  ) async {
    await _logEvent('verse_shared', {
      'surah_id': surahId,
      'verse_number': verseNumber,
      'method': method,
    });
  }

  Future<void> logSurahShared(int surahId, String method) async {
    await _logEvent('surah_shared', {'surah_id': surahId, 'method': method});
  }

  // Navigation Actions
  Future<void> logNavigationToJuz(int juzNumber) async {
    await _logEvent('navigation_to_juz', {'juz_number': juzNumber});
  }

  Future<void> logNavigationToPage(int pageNumber, String mushafType) async {
    await _logEvent('navigation_to_page', {
      'page_number': pageNumber,
      'mushaf_type': mushafType,
    });
  }

  // Error Tracking
  Future<void> logError(
    String errorType,
    String errorMessage, {
    String? feature,
    bool fatal = false,
  }) async {
    await _logEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'feature': feature ?? 'unknown',
      'fatal': fatal,
    });
  }

  // Performance Tracking
  Future<void> logPerformanceMetric(
    String metricName,
    int durationMs, {
    Map<String, dynamic>? attributes,
  }) async {
    final params = {
      'metric_name': metricName,
      'duration_ms': durationMs,
      ...?attributes,
    };
    await _logEvent('performance_metric', params);
  }

  // User Properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      Logger.debug('User property set: $name = $value', feature: 'Analytics');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to set user property',
        feature: 'Analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Generic Event Logging
  Future<void> _logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      // Convert to Map<String, Object> for Firebase Analytics
      final Map<String, Object> analyticsParams = {};
      parameters.forEach((key, value) {
        if (value != null) {
          if (value is String || value is num) {
            analyticsParams[key] = value;
          } else {
            analyticsParams[key] = value.toString();
          }
        }
      });

      await _analytics.logEvent(name: eventName, parameters: analyticsParams);
      Logger.debug('Event logged: $eventName', feature: 'Analytics');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to log event: $eventName',
        feature: 'Analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

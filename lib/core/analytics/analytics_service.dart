import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class AnalyticsService {
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

  final Map<String, DateTime> _screenEnter = {};

  Future<void> logScreenView({required String name, String? className}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logScreenView(screenName: name, screenClass: className);
  }

  void startScreenTimer(String name) {
    _screenEnter[name] = DateTime.now();
  }

  Future<void> endScreenTimer(String name) async {
    final start = _screenEnter.remove(name);
    if (start != null) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      final a = _analytics;
      if (a == null) return;
      await a.logEvent(
        name: 'screen_time',
        parameters: {'screen_name': name, 'duration_ms': ms},
      );
    }
  }

  Future<void> logLanguageChange(String code) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'language_change', parameters: {'code': code});
  }

  Future<void> logThemeChange(bool isDark) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'theme_toggle',
      parameters: {
        // Firebase Analytics only supports String or num parameter values
        'is_dark': isDark ? 1 : 0,
      },
    );
  }

  Future<void> logContinueReading(int surahId, double? offset) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'continue_reading',
      parameters: {'surah_id': surahId, 'offset': offset ?? 0.0},
    );
  }

  Future<void> logOpenSurah(int surahId) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'open_surah', parameters: {'surah_id': surahId});
  }

  Future<void> logLinkOpened(String url) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'open_link', parameters: {'url': url});
  }

  Future<void> logFeedbackSubmitted({required String method}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'feedback_submitted',
      parameters: {'method': method},
    );
  }

  // ── Quran.Foundation OAuth2 ──

  Future<void> logQfLogin({String? userId}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'qf_login',
      parameters: userId != null ? {'user_id_hash': userId.hashCode} : {},
    );
  }

  Future<void> logQfLogout() async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'qf_logout');
  }

  // ── Bookmarks ──

  Future<void> logBookmarkAdded({required int surahId, required int verseNumber}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'bookmark_added',
      parameters: {'surah_id': surahId, 'verse_number': verseNumber},
    );
  }

  Future<void> logBookmarkRemoved({required int surahId, required int verseNumber}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'bookmark_removed',
      parameters: {'surah_id': surahId, 'verse_number': verseNumber},
    );
  }

  // ── Cloud Sync ──

  Future<void> logCloudSync({required int pushed, required int pulled}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'cloud_sync',
      parameters: {'pushed': pushed, 'pulled': pulled},
    );
  }

  // ── Preference Sync ──

  Future<void> logPreferenceSync({required String direction, required int count}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'preference_sync',
      parameters: {'direction': direction, 'count': count},
    );
  }

  // ── Reading Sessions ──

  Future<void> logReadingSession({required int chapterNumber, required int versesRead}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'reading_session',
      parameters: {'chapter_number': chapterNumber, 'verses_read': versesRead},
    );
  }

  // ── Goals ──

  Future<void> logGoalUpdated(String goalId) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'goal_updated', parameters: {'goal_id': goalId});
  }

  Future<void> logGoalDeleted(String goalId) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'goal_deleted', parameters: {'goal_id': goalId});
  }

  // ── Quran Reflect ──

  Future<void> logReflectFeedViewed() async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'reflect_feed_viewed');
  }

  Future<void> logReflectPostTapped(String postId) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'reflect_post_tapped', parameters: {'post_id': postId});
  }

  // ── Verse Media ──

  Future<void> logVerseMediaViewed(int verseId) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'verse_media_viewed', parameters: {'verse_id': verseId});
  }

  // ── Search ──

  Future<void> logSearch(String query) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'search', parameters: {'query': query});
  }

  // ── Recitation ──

  Future<void> logRecitationVerified({required int surahId, required double accuracy}) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(
      name: 'recitation_verified',
      parameters: {'surah_id': surahId, 'accuracy': accuracy},
    );
  }

  // ── User archetype selection ──

  Future<void> logArchetypeSelected(String archetype) async {
    final a = _analytics;
    if (a == null) return;
    await a.logEvent(name: 'archetype_selected', parameters: {'archetype': archetype});
  }
}

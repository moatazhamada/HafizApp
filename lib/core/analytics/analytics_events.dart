/// Centralized Firebase Analytics event names.
///
/// Using constants prevents typos, enables IDE autocomplete, and makes
/// it easy to audit every event fired across the app.
class AnalyticsEvents {
  AnalyticsEvents._();

  // ── App Lifecycle ──
  static const String appOpen = 'app_open';
  static const String appBackground = 'app_background';
  static const String appForeground = 'app_foreground';

  // ── Screen Navigation ──
  static const String screenView = 'screen_view';
  static const String screenTime = 'screen_time';

  // ── User Preferences ──
  static const String languageChange = 'language_change';
  static const String themeToggle = 'theme_toggle';

  // ── Onboarding ──
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingStepViewed = 'onboarding_step_viewed';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String archetypeSelected = 'archetype_selected';

  // ── Reading ──
  static const String openSurah = 'open_surah';
  static const String openMushaf = 'open_mushaf';
  static const String continueReading = 'continue_reading';
  static const String readingSession = 'reading_session';
  static const String verseTapped = 'verse_tapped';
  static const String tafsirOpened = 'tafsir_opened';
  static const String tafsirSourceChanged = 'tafsir_source_changed';
  static const String translationToggled = 'translation_toggled';
  static const String autoScrollToggled = 'auto_scroll_toggled';
  static const String listeningModeToggled = 'listening_mode_toggled';

  // ── Audio ──
  static const String audioPlay = 'audio_play';
  static const String audioPause = 'audio_pause';
  static const String audioStop = 'audio_stop';
  static const String audioCompleted = 'audio_completed';
  static const String audioSpeedChanged = 'audio_speed_changed';
  static const String reciterChanged = 'reciter_changed';
  static const String sleepTimerSet = 'sleep_timer_set';
  static const String audioError = 'audio_error';

  // ── Memorization / Hifz ──
  static const String hifzModeToggled = 'hifz_mode_toggled';
  static const String verseRevealed = 'verse_revealed';
  static const String reviewStarted = 'review_started';
  static const String reviewCompleted = 'review_completed';
  static const String memorizationProgressViewed = 'memorization_progress_viewed';

  // ── Voice Recitation / QRC ──
  static const String recitationStarted = 'recitation_started';
  static const String recitationVerified = 'recitation_verified';
  static const String recitationErrorReported = 'recitation_error_reported';

  // ── Bookmarks ──
  static const String bookmarkAdded = 'bookmark_added';
  static const String bookmarkRemoved = 'bookmark_removed';
  static const String bookmarksViewed = 'bookmarks_viewed';

  // ── Search ──
  static const String search = 'search';
  static const String searchResultTapped = 'search_result_tapped';
  static const String searchEmpty = 'search_empty';

  // ── Quran Reflect ──
  static const String reflectFeedViewed = 'reflect_feed_viewed';
  static const String reflectPostTapped = 'reflect_post_tapped';

  // ── Verse Media ──
  static const String verseMediaViewed = 'verse_media_viewed';

  // ── Goals & Khatmah ──
  static const String goalUpdated = 'goal_updated';
  static const String goalDeleted = 'goal_deleted';
  static const String khatmahCreated = 'khatmah_created';
  static const String khatmahCompleted = 'khatmah_completed';

  // ── Cloud Sync ──
  static const String cloudSync = 'cloud_sync';
  static const String preferenceSync = 'preference_sync';
  static const String qfLogin = 'qf_login';
  static const String qfLogout = 'qf_logout';

  // ── Feedback & Links ──
  static const String feedbackSubmitted = 'feedback_submitted';
  static const String openLink = 'open_link';

  // ── Errors ──
  static const String apiError = 'api_error';
  static const String syncFailed = 'sync_failed';
  static const String unexpectedError = 'unexpected_error';

  // ── Notifications ──
  static const String notificationReceived = 'notification_received';
  static const String notificationTapped = 'notification_tapped';

  // ── Deep Links ──
  static const String deepLinkOpened = 'deep_link_opened';

  // ── Behavior ──
  static const String behaviorSessionRecorded = 'behavior_session_recorded';
  static const String dominantActionDetected = 'dominant_action_detected';
}

/// Centralized Firebase Analytics parameter keys.
class AnalyticsParams {
  AnalyticsParams._();

  static const String screenName = 'screen_name';
  static const String screenClass = 'screen_class';
  static const String durationMs = 'duration_ms';
  static const String code = 'code';
  static const String isDark = 'is_dark';
  static const String step = 'step';
  static const String totalSteps = 'total_steps';
  static const String archetype = 'archetype';
  static const String surahId = 'surah_id';
  static const String verseNumber = 'verse_number';
  static const String startVerse = 'start_verse';
  static const String endVerse = 'end_verse';
  static const String versesRead = 'verses_read';
  static const String durationSeconds = 'duration_seconds';
  static const String offset = 'offset';
  static const String chapterNumber = 'chapter_number';
  static const String tafsirSource = 'tafsir_source';
  static const String showTranslation = 'show_translation';
  static const String enabled = 'enabled';
  static const String speed = 'speed';
  static const String reciterId = 'reciter_id';
  static const String timerMinutes = 'timer_minutes';
  static const String errorMessage = 'error_message';
  static const String accuracy = 'accuracy';
  static const String query = 'query';
  static const String resultType = 'result_type';
  static const String resultIndex = 'result_index';
  static const String postId = 'post_id';
  static const String goalId = 'goal_id';
  static const String pushed = 'pushed';
  static const String pulled = 'pulled';
  static const String direction = 'direction';
  static const String count = 'count';
  static const String userIdHash = 'user_id_hash';
  static const String method = 'method';
  static const String url = 'url';
  static const String endpoint = 'endpoint';
  static const String statusCode = 'status_code';
  static const String notificationType = 'notification_type';
  static const String deepLinkUrl = 'deep_link_url';
  static const String action = 'action';
  static const String score = 'score';
  static const String source = 'source';
}

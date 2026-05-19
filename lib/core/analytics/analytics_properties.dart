/// Centralized Firebase Analytics user property names.
///
/// User properties are sticky attributes attached to the user device
/// and help segment audiences in the Firebase console.
class AnalyticsProperties {
  AnalyticsProperties._();

  /// The user's selected archetype during onboarding (e.g. 'student', 'seeker').
  static const String archetype = 'user_archetype';

  /// Current app locale (e.g. 'en', 'ar').
  static const String locale = 'app_locale';

  /// Current theme mode ('light', 'dark', 'system').
  static const String themeMode = 'theme_mode';

  /// Whether the user is logged into Quran Foundation.
  static const String isQfLoggedIn = 'is_qf_logged_in';

  /// The user's dominant behavior action detected locally ('read', 'memorize', 'search', etc.).
  static const String dominantAction = 'dominant_action';

  /// Whether the user has enabled translation display.
  static const String showTranslation = 'show_translation';

  /// The currently selected Mushaf type (e.g. 'madani', 'naskh').
  static const String mushafType = 'mushaf_type';

  /// The currently selected reciter CDN id.
  static const String reciterId = 'reciter_id';

  /// Whether the user has completed onboarding.
  static const String onboardingCompleted = 'onboarding_completed';

  /// The count of bookmarks the user has saved.
  static const String bookmarkCount = 'bookmark_count';

  /// Whether the user has any active khatmah.
  static const String hasActiveKhatmah = 'has_active_khatmah';

  /// The number of verses the user has memorized.
  static const String memorizedVerses = 'memorized_verses';
}

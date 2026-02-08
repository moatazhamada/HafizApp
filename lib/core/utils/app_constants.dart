/// Application-wide constants
/// Centralizes magic numbers and configuration values
class AppConstants {
  AppConstants._();

  // Search Configuration
  static const int searchMaxResults = 50;
  static const int searchMinQueryLength = 3;
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // Audio Configuration
  static const Duration audioSeekDuration = Duration(seconds: 10);
  static const Duration audioUpdateInterval = Duration(milliseconds: 100);
  static const List<int> sleepTimerOptions = [5, 10, 15, 30, 45, 60];
  static const List<double> playbackSpeedOptions = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Cache Configuration
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 100; // MB

  // Network Configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Quran Configuration
  static const int totalSurahs = 114;
  static const int totalVerses = 6236;
  static const int totalJuz = 30;
  static const int madaniMushafPages = 604;
  static const int indoPakMushafPages = 558;

  // Font Sizes
  static const double smallFontSize = 12.0;
  static const double normalFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 24.0;
  static const double arabicFontSize = 28.0;

  // Verse Display
  static const double verseSpacing = 12.0;
  static const double verseNumberSize = 32.0;
  static const int maxVerseLength = 300;

  // Bookmarks
  static const int maxBookmarks = 100;
  static const String bookmarkBoxName = 'bookmarks';
  static const String surahCacheBoxName = 'surah_cache';
  static const String recitationErrorBoxName = 'recitation_errors';
  static const String qiraatCacheBoxName = 'qiraat_cache';
  static const String audioCacheBoxName = 'audio_cache';

  // Analytics
  static const String screenViewEvent = 'screen_view';
  static const String userActionEvent = 'user_action';
  static const String errorEvent = 'error';

  // Deep Links
  static const String deepLinkScheme = 'hafiz';
  static const String deepLinkHost = 'app';

  // Image URLs
  static const String defaultArtworkUrl =
      'https://hafiz.app/assets/default_artwork.png';
  static const String bismillahImagePath = 'assets/images/bismillah.png';

  // Error Messages (Keys for localization)
  static const String errorNetworkKey = 'err_network';
  static const String errorCacheKey = 'err_cache';
  static const String errorServerKey = 'err_server';
  static const String errorUnknownKey = 'err_unknown';

  // Success Messages (Keys for localization)
  static const String msgBookmarkAddedKey = 'msg_bookmark_added';
  static const String msgBookmarkRemovedKey = 'msg_bookmark_removed';
  static const String msgDataSavedKey = 'msg_data_saved';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Performance
  static const int listViewCacheExtent = 500;
  static const int imageMemoryCacheSize = 100; // MB
  static const int imageDiskCacheSize = 200; // MB

  // Accessibility
  static const Duration minimumTapTargetDuration = Duration(milliseconds: 100);
  static const double minimumTapTargetSize = 48.0;

  // Recitation
  static const int defaultReciterId = 7; // Mishary Alafasy
  static const String defaultQiraatEdition = 'quran-uthmani';
  static const String defaultWhisperModel = 'base';

  // Theme
  static const String themeModeSystem = 'system';
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
}

import 'package:flutter/material.dart';
import 'package:hafiz_app/presentation/surah_screen/surah_screen.dart';
import '../presentation/bookmarks/bookmarks_screen.dart';
import '../presentation/help_screen/help_screen.dart';
import '../presentation/search/search_screen.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/about_screen/about_screen.dart';
import '../presentation/recitation_error/recitation_error_screen.dart';
import '../presentation/recitation_session/recitation_session_screen.dart';
import '../presentation/memorization/memorization_screen.dart';
import '../presentation/khatmah/khatmah_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/musali_teaser_screen/musali_teaser_screen.dart';
import '../presentation/cloud_sync/cloud_sync_screen.dart';

class AppRoutes {
  static const String onboardingScreen = '/OnboardingScreen';
  static const String homeScreen = '/home_screen'; // Changed from homePage
  static const String surahPage = '/surah_screen';
  static const String bookmarksPage =
      '/bookmarks'; // Changed path for bookmarksPage
  static const String searchPage = '/search_screen';
  static const String aboutPage = '/about_screen';
  static const String helpScreen = '/help';
  static const String recitationErrorsPage = '/recitation_errors';
  static const String recitationSessionsPage = '/recitation_sessions';
  static const String memorizationPage = '/memorization';
  static const String khatmahPage = '/khatmah';
  static const String settingsScreen = '/settings';
  static const String musaliTeaserScreen = '/musali_teaser_screen';
  static const String cloudSyncPage = '/cloud_sync';

  static Map<String, WidgetBuilder> routes = {
    // Changed from get routes =>
    onboardingScreen: OnboardingScreen.builder,
    homeScreen: (context) =>
        const HomeScreen(), // Changed from homePage and removed const
    surahPage: (context) => const SurahScreen(),
    searchPage: (context) => const SearchScreen(),
    bookmarksPage: (context) => const BookmarksScreen(),
    aboutPage: (context) =>
        const AboutScreen(), // Kept existing aboutPage route
    helpScreen: (context) => const HelpScreen(),
    recitationErrorsPage: (context) => const RecitationErrorScreen(),
    recitationSessionsPage: RecitationSessionScreen.builder,
    memorizationPage: MemorizationScreen.builder,
    khatmahPage: KhatmahScreen.builder,
    settingsScreen: (context) => const SettingsScreen(),
    musaliTeaserScreen: MusaliTeaserScreen.builder,
    cloudSyncPage: (context) => const CloudSyncScreen(),
  };
}

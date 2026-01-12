import 'package:flutter/material.dart';
import 'package:hafiz_app/presentation/surah_screen/surah_screen.dart';
import '../presentation/bookmarks/bookmarks_screen.dart';
import '../presentation/help_screen/help_screen.dart';
import '../presentation/search/search_screen.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/about_screen/about_screen.dart';

class AppRoutes {
  static const String onboardingScreen = '/OnboardingScreen';
  static const String homeScreen = '/home_screen'; // Changed from homePage
  static const String surahPage = '/surah_screen';
  static const String bookmarksPage =
      '/bookmarks'; // Changed path for bookmarksPage
  static const String searchPage = '/search_screen';
  static const String aboutPage = '/about_screen';
  static const String helpScreen = '/help'; // Added helpScreen constant

  static Map<String, WidgetBuilder> routes = {
    // Changed from get routes =>
    onboardingScreen: (context) =>
        const OnboardingScreen(), // Changed builder to direct constructor
    homeScreen: (context) =>
        HomeScreen(), // Changed from homePage and removed const
    surahPage: (context) => const SurahScreen(),
    searchPage: (context) => const SearchScreen(),
    bookmarksPage: (context) => const BookmarksScreen(),
    aboutPage: (context) =>
        const AboutScreen(), // Kept existing aboutPage route
    helpScreen: (context) => const HelpScreen(), // Added helpScreen route
  };
}

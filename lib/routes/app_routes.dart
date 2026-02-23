import 'package:flutter/material.dart';
import 'package:hafiz_app/presentation/surah_screen/surah_screen.dart';
import '../presentation/bookmarks/bookmarks_screen.dart';
import '../presentation/help_screen/help_screen.dart';
import '../presentation/search/search_screen.dart';
import '../presentation/statistics_screen/statistics_screen.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/about_screen/about_screen.dart';
import '../presentation/recitation_error/recitation_error_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/mushaf_screen/mushaf_screen.dart';
import '../presentation/audio_player/audio_player_screen.dart';
import '../presentation/onboarding_screen/mushaf_type_onboarding.dart';

import '../core/quran_index/quran_surah.dart';
import '../core/quran_index/mushaf_types.dart';

class AppRoutes {
  static const String onboardingScreen = '/OnboardingScreen';
  static const String homeScreen = '/home_screen';
  static const String surahPage = '/surah_screen';
  static const String bookmarksPage = '/bookmarks';
  static const String searchPage = '/search_screen';
  static const String aboutPage = '/about_screen';
  static const String helpScreen = '/help';
  static const String recitationErrorsPage = '/recitation_errors';
  static const String settingsScreen = '/settings';
  static const String mushafScreen = '/mushaf';
  static const String audioPlayerScreen = '/audio_player';
  static const String statisticsScreen = '/statistics';

  static Map<String, WidgetBuilder> routes = {
    onboardingScreen: OnboardingScreen.builder,
    homeScreen: (context) => const HomeScreen(),
    surahPage: (context) => const SurahScreen(),
    searchPage: (context) => const SearchScreen(),
    bookmarksPage: (context) => const BookmarksScreen(),
    aboutPage: (context) => const AboutScreen(),
    helpScreen: (context) => const HelpScreen(),
    recitationErrorsPage: (context) => const RecitationErrorScreen(),
    settingsScreen: (context) => const SettingsScreen(),
    mushafScreen: (context) => const MushafScreen(),
    statisticsScreen: StatisticsScreen.builder,
  };

  /// Navigate to Mushaf screen with optional parameters
  static void goToMushaf(
    BuildContext context, {
    int? page,
    int? surah,
    int? verse,
    MushafType? mushafType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MushafScreen(
          initialPage: page,
          highlightSurah: surah,
          highlightVerse: verse,
          mushafType: mushafType ?? MushafType.madani,
        ),
      ),
    );
  }

  /// Navigate to Mushaf type onboarding
  static void goToMushafOnboarding(
    BuildContext context, {
    required VoidCallback onComplete,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MushafTypeOnboarding(onComplete: onComplete),
      ),
    );
  }

  /// Navigate to Audio Player
  static void goToAudioPlayer(
    BuildContext context, {
    required Surah surah,
    int? startVerse,
    required String reciter,
    required List<String> audioUrls,
    required List<Duration> verseTimestamps,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioPlayerScreen(
          surah: surah,
          startVerse: startVerse,
          reciter: reciter,
          audioUrls: audioUrls,
          verseTimestamps: verseTimestamps,
        ),
      ),
    );
  }
}

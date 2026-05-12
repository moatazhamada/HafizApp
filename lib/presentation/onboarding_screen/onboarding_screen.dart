import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'archetype_selection_page.dart';
import 'language_selection_page.dart';
import 'onboarding_welcome_page.dart';
import 'theme_selection_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Widget builder(BuildContext context) {
    return const OnboardingScreen();
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      // After archetype selection, go to mushaf type onboarding
      NavigatorService.pushNamedAndRemoveUntil(
        AppRoutes.mushafTypeOnboarding,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LanguageSelectionPage(onContinue: _nextPage),
          ThemeSelectionPage(onContinue: _nextPage),
          OnboardingWelcomePage(onContinue: _nextPage),
          ArchetypeSelectionPage(onContinue: _nextPage),
        ],
      ),
    );
  }
}

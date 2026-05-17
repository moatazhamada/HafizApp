import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/app_export.dart';
import '../../core/utils/rtl_utils.dart';
import '../../injection_container.dart';
import '../../main.dart';
import 'archetype_selection_page.dart';
import 'language_selection_page.dart';
import 'notification_permission_page.dart';
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
  String? _themeMode;

  bool get _isLightBackground {
    if (_themeMode == 'light') return true;
    if (_themeMode == 'dark') return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.light;
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      unawaited(
        sl<AnalyticsService>().logOnboardingStepViewed(
          step: _currentPage + 1,
          totalSteps: 5,
        ),
      );
    } else {
      // After notification permission, go to mushaf type onboarding
      unawaited(sl<AnalyticsService>().logOnboardingCompleted());
      NavigatorService.pushNamedAndRemoveUntil(
        AppRoutes.mushafTypeOnboarding,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void _onThemeModeChanged(String mode) {
    setState(() => _themeMode = mode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          _previousPage();
        }
      },
      child: Theme(
        data: _isLightBackground ? lightTheme : darkTheme,
        child: Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
              children: [
                LanguageSelectionPage(
                  onContinue: _nextPage,
                  themeMode: _themeMode,
                  isLightBackground: _isLightBackground,
                ),
                ThemeSelectionPage(
                  onContinue: _nextPage,
                  onBack: _previousPage,
                  themeMode: _themeMode,
                  isLightBackground: _isLightBackground,
                  onThemeModeChanged: _onThemeModeChanged,
                ),
                OnboardingWelcomePage(
                  onContinue: _nextPage,
                  onBack: _previousPage,
                  themeMode: _themeMode,
                  isLightBackground: _isLightBackground,
                ),
                ArchetypeSelectionPage(
                  onContinue: _nextPage,
                  onBack: _previousPage,
                  themeMode: _themeMode,
                  isLightBackground: _isLightBackground,
                ),
                NotificationPermissionPage(
                  onContinue: _nextPage,
                  onBack: _previousPage,
                  themeMode: _themeMode,
                  isLightBackground: _isLightBackground,
                ),
              ],
            ),
            // Back button on pages 1+
            if (_currentPage > 0)
              PositionedDirectional(
                top: 16,
                start: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _previousPage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isLightBackground
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          rtlBackArrow(context),
                          color: _isLightBackground
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}

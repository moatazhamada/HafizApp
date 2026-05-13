import 'package:flutter/material.dart';

/// Shared scaffold for all onboarding screens.
///
/// Adapts its background to the selected theme mode so users can preview
/// their choice immediately during onboarding.
class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final double? maxContentWidth;
  final String? themeMode;

  const OnboardingScaffold({
    super.key,
    required this.child,
    this.maxContentWidth = 600,
    this.themeMode,
  });

  bool get _isLight {
    if (themeMode == 'light') return true;
    if (themeMode == 'dark') return false;
    // system or null — use platform brightness
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF001A16),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5F7FA),
                    Color(0xFFEEF2F5),
                    Color(0xFFE8ECEF),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D2926),
                    Color(0xFF061F1B),
                    Color(0xFF001A16),
                  ],
                ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth > 900;

              if (isLarge && maxContentWidth != null) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth!),
                    child: child,
                  ),
                );
              }
              return child;
            },
          ),
        ),
      ),
    );
  }
}

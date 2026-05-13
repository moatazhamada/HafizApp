import 'package:flutter/material.dart';

/// Shared scaffold for all onboarding screens.
///
/// Provides a deep dark-teal gradient background for maximum contrast
/// with white text, buttons, and selection cards.
class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final double? maxContentWidth;

  const OnboardingScaffold({
    super.key,
    required this.child,
    this.maxContentWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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

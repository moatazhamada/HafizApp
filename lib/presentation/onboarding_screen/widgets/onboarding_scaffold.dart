import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared scaffold for all onboarding screens.
///
/// Provides consistent gradient background, safe area, responsive layout,
/// and large-screen centering.
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.85),
              colorScheme.primary,
              AppColors.of(context).primaryDark,
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

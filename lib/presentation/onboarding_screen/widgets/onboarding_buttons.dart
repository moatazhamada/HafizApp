import 'package:flutter/material.dart';

/// Primary action button for onboarding screens.
///
/// Adapts its colors to the onboarding background (light or dark).
class OnboardingPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final bool isLightBackground;

  const OnboardingPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width ?? double.maxFinite,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isLightBackground
              ? colorScheme.primary
              : Colors.white,
          foregroundColor: isLightBackground
              ? Colors.white
              : colorScheme.primary,
          disabledBackgroundColor: isLightBackground
              ? colorScheme.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.4),
          disabledForegroundColor: isLightBackground
              ? Colors.white.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Secondary action button for onboarding screens.
///
/// Transparent background with adaptive text color.
class OnboardingSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLightBackground;

  const OnboardingSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isLightBackground
            ? colorScheme.primary
            : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Selection card used in onboarding for choosing options.
///
/// Semi-transparent background that highlights when selected.
/// Adapts colors for light or dark onboarding backgrounds.
class OnboardingSelectionCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLightBackground;

  const OnboardingSelectionCard({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? (isLightBackground
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.2))
          : (isLightBackground
              ? colorScheme.primary.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.1)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isLightBackground
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.6))
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Onboarding page header with icon, title, and subtitle.
///
/// Uses white text for readability on gradient backgrounds.
class OnboardingHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const OnboardingHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

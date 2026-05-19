import 'package:flutter/material.dart';

import '../core/app_export.dart';

/// Standardized error-state widget used across the app.
///
/// Use whenever data fails to load or a BLoC emits an error state.
/// Provides consistent visual treatment and a retry affordance.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.message,
    this.retryLabel = 'lbl_retry',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

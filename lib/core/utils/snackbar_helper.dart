import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';

enum SnackBarType { info, success, warning, error }

class SnackBarHelper {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final Color backgroundColor;
    final Color foregroundColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = colors.memorizedStatus;
        foregroundColor = Colors.white;
      case SnackBarType.warning:
        backgroundColor = colors.inProgressStatus;
        foregroundColor = Colors.white;
      case SnackBarType.error:
        backgroundColor = colors.needsReviewStatus;
        foregroundColor = Colors.white;
      case SnackBarType.info:
        backgroundColor = theme.colorScheme.inverseSurface;
        foregroundColor = theme.colorScheme.onInverseSurface;
    }

    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: foregroundColor),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: foregroundColor,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

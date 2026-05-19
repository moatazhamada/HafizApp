import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

void showCompletionDialog(
  BuildContext context, {
  required double percentage,
  required VoidCallback onClose,
}) {
  if (percentage >= 50) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('lbl_congrats'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.celebration, color: AppColors.of(context).memorizedStatus, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              'msg_session_score'.tr.replaceAll(
                '{score}',
                percentage.toStringAsFixed(1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              onClose();
              Navigator.pop(dialogContext);
            },
            child: Text('lbl_close'.tr),
          ),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('lbl_keep_practicing'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.fitness_center,
                color: AppColors.of(context).inProgressStatus,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'msg_session_score'.tr.replaceAll(
                '{score}',
                percentage.toStringAsFixed(1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_keep_practicing'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              onClose();
              Navigator.pop(dialogContext);
            },
            child: Text('lbl_close'.tr),
          ),
        ],
      ),
    );
  }
}

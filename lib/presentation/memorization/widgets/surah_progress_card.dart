import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';

class SurahProgressCard extends StatelessWidget {
  final MemorizationProgress progress;
  final bool isDark;
  final VoidCallback onLogReview;
  final VoidCallback onRead;

  const SurahProgressCard({
    super.key,
    required this.progress,
    required this.isDark,
    required this.onLogReview,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, progress.status);
    final statusLabel = _statusLabel(progress.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Semantics(
          label: 'lbl_semantics_status'.tr.replaceAll('{status}', statusLabel),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '${progress.surahId}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
        title: Text(
          progress.surahName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '$statusLabel • ${'lbl_best_score'.tr}: ${progress.bestScore.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.of(context).textSecondary),
          onSelected: (value) {
            if (value == 'log_review') {
              onLogReview();
            } else if (value == 'read') {
              onRead();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'log_review',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: AppColors.of(context).memorizedStatus),
                  const SizedBox(width: 8),
                  Text('lbl_log_review'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'read',
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, size: 18),
                  const SizedBox(width: 8),
                  Text('lbl_read_this_ayah'.tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, MemorizationStatus status) {
    final colors = AppColors.of(context);
    switch (status) {
      case MemorizationStatus.memorized:
        return colors.memorizedStatus;
      case MemorizationStatus.inProgress:
        return colors.inProgressStatus;
      case MemorizationStatus.needsReview:
        return colors.needsReviewStatus;
      case MemorizationStatus.notStarted:
        return colors.notStartedStatus;
    }
  }

  String _statusLabel(MemorizationStatus status) {
    switch (status) {
      case MemorizationStatus.memorized:
        return 'lbl_memorized'.tr;
      case MemorizationStatus.inProgress:
        return 'lbl_in_progress'.tr;
      case MemorizationStatus.needsReview:
        return 'lbl_needs_review'.tr;
      case MemorizationStatus.notStarted:
        return 'lbl_not_started'.tr;
    }
  }
}

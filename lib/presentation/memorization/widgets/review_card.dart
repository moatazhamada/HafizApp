import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/srs/srs_algorithm.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';

class ReviewCard extends StatelessWidget {
  final MemorizationProgress progress;
  final bool isDark;
  final VoidCallback onLogReview;
  final VoidCallback onRead;

  const ReviewCard({
    super.key,
    required this.progress,
    required this.isDark,
    required this.onLogReview,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyKey = SrsAlgorithm.urgencyLabel(progress);
    final daysUntil = SrsAlgorithm.daysUntilReview(progress);
    final urgency = urgencyKey == 'lbl_review_urgency_overdue_days'
        ? urgencyKey.tr.replaceAll('{days}', '${-daysUntil}')
        : urgencyKey.tr;
    final isOverdue = daysUntil < 0;
    final urgencyColor = isOverdue ? AppColors.of(context).needsReviewStatus : AppColors.of(context).inProgressStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: urgencyColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          isOverdue ? Icons.alarm : Icons.notifications_active,
          color: urgencyColor,
        ),
        title: Text(progress.surahName),
        subtitle: Text(
          '${'lbl_best_score'.tr}: ${progress.bestScore.toStringAsFixed(0)}% • '
          '${'lbl_interval'.tr}: ${progress.interval}${'lbl_days'.tr}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'lbl_semantics_status'.tr.replaceAll('{status}', urgency),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'lbl_log_review'.tr,
              child: IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.of(context).memorizedStatus,
                ),
                tooltip: 'lbl_log_review'.tr,
                onPressed: onLogReview,
              ),
            ),
            Semantics(
              button: true,
              label: 'lbl_read_this_ayah'.tr,
              child: IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: AppColors.of(context).primary,
                ),
                tooltip: 'lbl_read_this_ayah'.tr,
                onPressed: onRead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final int cloudStreak;
  final int localStreak;
  final bool isDark;
  final AppColors colors;

  const StreakCard({
    super.key,
    required this.streak,
    required this.cloudStreak,
    required this.localStreak,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.inProgressStatus.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colors.inProgressStatus.withValues(alpha: 0.08),
              colors.inProgressStatus.withValues(alpha: 0.04),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.inProgressStatus.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                streak > 0
                    ? Icons.local_fire_department_rounded
                    : Icons.local_fire_department_outlined,
                color: streak > 0 ? colors.inProgressStatus : colors.notStartedStatus,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'stats_streak'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$streak ${'lbl_day_streak'.tr}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: streak > 0 ? colors.inProgressStatus : colors.notStartedStatus,
                    ),
                  ),
                  if (cloudStreak > 0)
                    Text(
                      'stats_cloud_streak'.tr.replaceAll(
                        '{count}',
                        '$cloudStreak',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

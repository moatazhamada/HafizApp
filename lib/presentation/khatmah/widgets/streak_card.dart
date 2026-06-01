import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/presentation/khatmah/widgets/streak_source_chip.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final int cloudStreak;
  final int localStreak;

  const StreakCard({
    required this.streak,
    this.cloudStreak = 0,
    this.localStreak = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: streak > 0
                        ? AppColors.of(context).inProgressStatus.withValues(alpha: 0.15)
                        : AppColors.of(context).notStartedStatus.withValues(alpha: 0.15),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: streak > 0 ? AppColors.of(context).inProgressStatus : AppColors.of(context).notStartedStatus,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak ${'lbl_day_streak'.tr}',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'lbl_keep_going'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (cloudStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).memorizedStatus.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, size: 14, color: AppColors.of(context).success),
                        const SizedBox(width: 4),
                        Text(
                          'lbl_cloud_synced'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.of(context).success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (localStreak != streak)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreakSourceChip(
                      label: 'lbl_local_streak'.tr,
                      value: localStreak,
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    StreakSourceChip(
                      label: 'lbl_cloud_streak'.tr,
                      value: cloudStreak > 0 ? cloudStreak + localStreak : 0,
                      icon: Icons.cloud,
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

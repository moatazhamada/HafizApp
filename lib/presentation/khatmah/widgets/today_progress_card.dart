import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_state.dart';

class TodayProgressCard extends StatelessWidget {
  final KhatmahDashboardLoaded state;

  const TodayProgressCard({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = state.todayProgress;
    final target = state.goal?.dailyVerseTarget ?? 0;

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              'lbl_today_reading'.tr,
              style: AppTextStyles.headingMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.versesReadToday}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '/ $target ${'lbl_verses'.tr}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              progress >= 1.0
                  ? 'msg_goal_achieved'.tr
                  : 'msg_verses_remaining'.tr.replaceAll(
                      '{count}',
                      '${target - state.versesReadToday}',
                    ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: progress >= 1.0 ? AppColors.of(context).memorizedStatus : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: progress >= 1.0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

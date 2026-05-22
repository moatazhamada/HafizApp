import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_state.dart';

class WeeklyHeatmap extends StatelessWidget {
  final KhatmahDashboardLoaded state;

  const WeeklyHeatmap({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = state.goal?.dailyVerseTarget ?? 0;

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_last_7_days'.tr,
              style: AppTextStyles.headingMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final date = today.subtract(Duration(days: 6 - i));
                final log = state.recentLogs.where(
                  (l) =>
                      l.date.year == date.year &&
                      l.date.month == date.month &&
                      l.date.day == date.day,
                );
                final verses = log.isNotEmpty ? log.first.versesRead : 0;
                final met = target > 0 && verses >= target;
                final partial = verses > 0;

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: met
                            ? colors.primary
                            : partial
                            ? colors.primary.withValues(alpha: 0.3)
                            : isDark
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      alignment: Alignment.center,
                      child: met
                          ? Icon(Icons.check, color: colors.onPrimary, size: 20)
                          : Text(
                              '$verses',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _dayAbbr(date.weekday),
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _dayAbbr(int weekday) {
    final days = [
      'lbl_mon'.tr,
      'lbl_tue'.tr,
      'lbl_wed'.tr,
      'lbl_thu'.tr,
      'lbl_fri'.tr,
      'lbl_sat'.tr,
      'lbl_sun'.tr,
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }
}

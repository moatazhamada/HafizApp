import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../bloc/goals_bloc.dart';

class SummaryHeader extends StatelessWidget {
  final List<PlanItem> items;
  final AppColors colors;
  final ThemeData theme;
  const SummaryHeader({
    super.key,
    required this.items,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final completed = items.where((i) {
      final p = i.progress ?? 0;
      final d = i.duration ?? 0;
      return d > 0 && p >= d;
    }).length;

    return Card(
      elevation: 0,
      color: colors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lbl_today_reading'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'goals_items_count'.tr.replaceAll(
                      '{count}',
                      '${items.length}',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primaryDark.withValues(alpha: 0.7),
                    ),
                  ),
                  if (completed > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$completed ${'goals_completed'.tr.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.of(context).success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

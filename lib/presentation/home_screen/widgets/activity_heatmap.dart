import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../domain/entities/reading_goal.dart';

/// A GitHub-style contribution heatmap showing daily Quran reading activity.
/// Visualizes the last 28 days of reading logs.
class ActivityHeatmap extends StatelessWidget {
  final List<DailyReadingLog> logs;
  final int maxVerseTarget;

  const ActivityHeatmap({
    super.key,
    required this.logs,
    this.maxVerseTarget = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Build a map of date -> verses read
    final activityMap = <String, int>{};
    for (final log in logs) {
      final key = _dateKey(log.date);
      activityMap[key] = (activityMap[key] ?? 0) + log.versesRead;
    }

    // Generate last 28 days
    final now = DateTime.now();
    final days = List.generate(28, (i) {
      final date = now.subtract(Duration(days: 27 - i));
      final key = _dateKey(date);
      return _DayActivity(
        date: date,
        versesRead: activityMap[key] ?? 0,
      );
    });

    // Group into 4 weeks
    final weeks = <List<_DayActivity>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'lbl_activity_heatmap'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weeks.map((week) {
                return Column(
                  children: week.map((day) {
                    final intensity = _intensity(day.versesRead);
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: Tooltip(
                        message: _tooltip(day),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _color(intensity, colorScheme, isDark),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'lbl_less'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                ...List.generate(4, (i) {
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _color(i / 3, colorScheme, isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  'lbl_more'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _intensity(int verses) {
    if (verses <= 0) return 0;
    return (verses / maxVerseTarget).clamp(0.0, 1.0);
  }

  Color _color(double intensity, ColorScheme scheme, bool isDark) {
    if (intensity <= 0) {
      return isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    return Color.lerp(
      scheme.primary.withValues(alpha: 0.15),
      scheme.primary,
      intensity,
    )!;
  }

  String _tooltip(_DayActivity day) {
    final dateStr =
        '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
    if (day.versesRead <= 0) return '$dateStr: ${'lbl_no_reading'.tr}';
    return '$dateStr: ${day.versesRead} ${'lbl_verses_read'.tr}';
  }
}

class _DayActivity {
  final DateTime date;
  final int versesRead;

  _DayActivity({required this.date, required this.versesRead});
}

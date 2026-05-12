import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../domain/entities/reading_goal.dart';

/// Shows today's reading duration and a weekly summary.
class ReadingSessionInsights extends StatelessWidget {
  final List<DailyReadingLog> recentLogs;

  const ReadingSessionInsights({
    super.key,
    required this.recentLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final today = DateTime.now();
    final todayLog = _findLogForDate(today);
    final weekLogs = _getLast7Days();
    final weekTotalVerses = weekLogs.fold<int>(
      0,
      (sum, log) => sum + log.versesRead,
    );
    final weekTotalDuration = weekLogs.fold<Duration>(
      Duration.zero,
      (sum, log) => sum + log.readingDuration,
    );

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
                  Icons.timer_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'lbl_reading_insights'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InsightPill(
                    icon: Icons.today_rounded,
                    label: 'lbl_today'.tr,
                    value: _formatDuration(todayLog?.readingDuration ?? Duration.zero),
                    subValue: '${todayLog?.versesRead ?? 0} ${'lbl_verses'.tr}',
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightPill(
                    icon: Icons.calendar_view_week_rounded,
                    label: 'lbl_this_week'.tr,
                    value: _formatDuration(weekTotalDuration),
                    subValue: '$weekTotalVerses ${'lbl_verses'.tr}',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WeeklyBarChart(logs: weekLogs),
          ],
        ),
      ),
    );
  }

  DailyReadingLog? _findLogForDate(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return recentLogs.firstWhere(
        (log) => _dateKey(log.date) == key,
      );
    } catch (_) {
      return null;
    }
  }

  List<DailyReadingLog> _getLast7Days() {
    final now = DateTime.now();
    final result = <DailyReadingLog>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final log = _findLogForDate(date);
      if (log != null) result.add(log);
    }
    return result;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
}

class _InsightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _InsightPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyReadingLog> logs;

  const _WeeklyBarChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate last 7 days regardless of whether there are logs
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final log = logs.cast<DailyReadingLog?>().firstWhere(
        (l) =>
            l != null &&
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day,
        orElse: () => null,
      );
      return _DayBar(
        date: date,
        versesRead: log?.versesRead ?? 0,
      );
    });

    final maxVerses = days.map((d) => d.versesRead).reduce((a, b) => a > b ? a : b);
    final maxValue = maxVerses < 10 ? 10 : maxVerses;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) {
        final heightFactor = maxValue > 0 ? day.versesRead / maxValue : 0.0;
        return Tooltip(
          message: '${day.date.day}/${day.date.month}: ${day.versesRead} ${'lbl_verses'.tr}',
          child: Column(
            children: [
              Container(
                width: 24,
                height: 60,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 16,
                  height: 60 * heightFactor.clamp(0.05, 1.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: 0.2 + (0.8 * heightFactor),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dayLabel(day.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _dayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

class _DayBar {
  final DateTime date;
  final int versesRead;

  _DayBar({required this.date, required this.versesRead});
}

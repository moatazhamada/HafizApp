import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_state.dart';
import 'package:hafiz_app/injection_container.dart';

class KhatmahScreen extends StatelessWidget {
  const KhatmahScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<KhatmahBloc>()..add(LoadKhatmahDashboard()),
      child: const KhatmahScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('lbl_khatmah_tracker'.tr)),
      body: BlocBuilder<KhatmahBloc, KhatmahState>(
        builder: (context, state) {
          if (state is KhatmahLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is KhatmahError) {
            return Center(child: Text(state.message));
          }
          if (state is KhatmahDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<KhatmahBloc>().add(LoadKhatmahDashboard());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TodayProgressCard(state: state, isDark: isDark),
                  const SizedBox(height: 16),
                  _StreakCard(streak: state.streak, isDark: isDark),
                  const SizedBox(height: 16),
                  _GoalCard(state: state, isDark: isDark),
                  const SizedBox(height: 16),
                  _WeeklyHeatmap(state: state, isDark: isDark),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  final KhatmahDashboardLoaded state;
  final bool isDark;

  const _TodayProgressCard({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = state.todayProgress;
    final target = state.goal?.dailyVerseTarget ?? 0;

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'lbl_today_reading'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
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
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF006754),
                    ),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '/ $target ${'lbl_verses'.tr}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              progress >= 1.0
                  ? 'msg_goal_achieved'.tr
                  : 'msg_verses_remaining'.tr.replaceAll(
                      '{count}',
                      '${target - state.versesReadToday}',
                    ),
              style: TextStyle(
                fontSize: 14,
                color: progress >= 1.0 ? Colors.green : Colors.grey[600],
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

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool isDark;

  const _StreakCard({required this.streak, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: streak > 0
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department,
                size: 32,
                color: streak > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak ${'lbl_day_streak'.tr}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'lbl_keep_going'.tr,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

class _GoalCard extends StatelessWidget {
  final KhatmahDashboardLoaded state;
  final bool isDark;

  const _GoalCard({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentTarget = state.goal?.dailyVerseTarget ?? 0;
    final presets = [10, 20, 50, 100, 200];

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_daily_goal'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((target) {
                final isSelected = target == currentTarget;
                return ChoiceChip(
                  label: Text('$target'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF006754).withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF006754)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                  onSelected: (_) {
                    context.read<KhatmahBloc>().add(SetReadingGoal(target));
                  },
                );
              }).toList(),
            ),
            if (currentTarget > 0 && !presets.contains(currentTarget))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${'lbl_current_goal'.tr}: $currentTarget ${'lbl_verses'.tr}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyHeatmap extends StatelessWidget {
  final KhatmahDashboardLoaded state;
  final bool isDark;

  const _WeeklyHeatmap({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = state.goal?.dailyVerseTarget ?? 0;

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'lbl_last_7_days'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
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
                            ? const Color(0xFF006754)
                            : partial
                            ? const Color(0xFF006754).withValues(alpha: 0.3)
                            : isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                      ),
                      alignment: Alignment.center,
                      child: met
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '$verses',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayAbbr(date.weekday),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

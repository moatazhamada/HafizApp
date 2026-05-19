import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_bloc.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_event.dart';
import 'package:hafiz_app/presentation/khatmah/bloc/khatmah_state.dart';
import 'package:hafiz_app/widgets/shimmer_loading.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/khatmah/widgets/manual_reading_entry_bottom_sheet.dart';

import 'package:hafiz_app/presentation/khatmah/widgets/goal_celebration.dart';
import 'package:intl/intl.dart';

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider.value(
      value: sl<KhatmahBloc>()..add(LoadKhatmahDashboard()),
      child: const KhatmahScreen(),
    );
  }

  @override
  State<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends State<KhatmahScreen> {
  bool _showCelebration = false;
  String? _celebrationTitle;

  void _checkGoalCelebration(KhatmahState state) {
    if (state is KhatmahDashboardLoaded) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastCelebrated = PrefUtils().getLastCelebratedDate();

      // Check daily goal
      if (state.todayProgress >= 1.0 && lastCelebrated != todayStr) {
        _triggerCelebration('msg_daily_goal_achieved'.tr, todayStr);
        return;
      }

      // Check streak milestones
      final lastStreakCelebrated = PrefUtils().getLastStreakCelebrated() ?? 0;
      final currentStreak = state.streak;
      final milestones = [3, 7, 14, 30, 50, 100, 365];

      for (final m in milestones) {
        if (currentStreak >= m && lastStreakCelebrated < m) {
          _triggerCelebration(
            'msg_streak_milestone'.tr.replaceAll('{days}', m.toString()),
            null, // Date handled separately for streak
          );
          PrefUtils().setLastStreakCelebrated(m);
          break;
        }
      }
    }
  }

  void _triggerCelebration(String title, String? dateKey) {
    setState(() {
      _showCelebration = true;
      _celebrationTitle = title;
    });
    if (dateKey != null) {
      PrefUtils().setLastCelebratedDate(dateKey);
    }
    // Hide celebration after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
          _celebrationTitle = null;
        });
      }
    });
  }

  void _checkKhatmahCompletion(BuildContext context) {
    if (PrefUtils().shouldShowDuaKhatm()) {
      PrefUtils().setShouldShowDuaKhatm(false);
      _showKhatmahCompletionDialog(context);
    }
  }

  void _showKhatmahCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.menu_book_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: Text(
          'lbl_khatmah_completed'.tr,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'msg_khatmah_completed'.tr,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('lbl_close'.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              NavigatorService.pushNamed(AppRoutes.duaKhatm);
            },
            child: Text('lbl_read_dua'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_khatmah_tracker'.tr)),
      body: BlocConsumer<KhatmahBloc, KhatmahState>(
        listener: (context, state) {
          _checkGoalCelebration(state);
          _checkKhatmahCompletion(context);
        },
        builder: (context, state) {
          if (state is KhatmahLoading) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ListView(
                children: const [
                  ShimmerCard(height: 240),
                  SizedBox(height: AppSpacing.lg),
                  ShimmerCard(height: 100),
                  SizedBox(height: AppSpacing.lg),
                  ShimmerCard(height: 140),
                  SizedBox(height: AppSpacing.lg),
                  ShimmerCard(height: 120),
                ],
              ),
            );
          }
          if (state is KhatmahError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message.tr),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.read<KhatmahBloc>().add(LoadKhatmahDashboard()),
                    child: Text('lbl_retry'.tr),
                  ),
                ],
              ),
            );
          }
          if (state is KhatmahDashboardLoaded) {
            return GoalCelebration(
              showConfetti: _showCelebration,
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<KhatmahBloc>().add(LoadKhatmahDashboard());
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _TodayProgressCard(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _StreakCard(
                          streak: state.streak,
                          cloudStreak: state.cloudStreak,
                          localStreak: state.localStreak,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _GoalCard(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _WeeklyHeatmap(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _DuaKhatmCard(
                          completions: PrefUtils().getKhatmahCompletionsCount(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  if (_showCelebration && _celebrationTitle != null)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text(
                              _celebrationTitle!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final bloc = context.read<KhatmahBloc>();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ManualReadingEntryBottomSheet(
              onSubmit: (verses) {
                bloc.add(RecordReading(verses: verses));
              },
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text('lbl_log_reading'.tr),
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  final KhatmahDashboardLoaded state;

  const _TodayProgressCard({required this.state});

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

class _StreakCard extends StatelessWidget {
  final int streak;
  final int cloudStreak;
  final int localStreak;

  const _StreakCard({
    required this.streak,
    this.cloudStreak = 0,
    this.localStreak = 0,
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
                    _StreakSourceChip(
                      label: 'lbl_local_streak'.tr,
                      value: localStreak,
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StreakSourceChip(
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

class _StreakSourceChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StreakSourceChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final KhatmahDashboardLoaded state;

  const _GoalCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currentTarget = state.goal?.dailyVerseTarget ?? 0;
    final presets = [10, 20, 50, 100, 200];

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
              'lbl_daily_goal'.tr,
              style: AppTextStyles.headingMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (state.cloudStreak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
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
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: presets.map((target) {
                final isSelected = target == currentTarget;
                return ChoiceChip(
                  label: Text('$target'),
                  selected: isSelected,
                  selectedColor: colors.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primary
                        : AppColors.of(context).notStartedStatus.withValues(alpha: 0.3),
                  ),
                  onSelected: (_) {
                    context.read<KhatmahBloc>().add(SetReadingGoal(target));
                  },
                );
              }).toList(),
            ),
            if (currentTarget > 0 && !presets.contains(currentTarget))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '${'lbl_current_goal'.tr}: $currentTarget ${'lbl_verses'.tr}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
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

  const _WeeklyHeatmap({required this.state});

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

class _DuaKhatmCard extends StatelessWidget {
  final int completions;

  const _DuaKhatmCard({this.completions = 0});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => NavigatorService.pushNamed(AppRoutes.duaKhatm),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_dua_khatm'.tr,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (completions > 0)
                      Text(
                        'msg_khatmah_count'
                            .tr
                            .replaceAll('{count}', '$completions'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

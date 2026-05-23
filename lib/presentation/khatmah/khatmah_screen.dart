import 'dart:async';

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
import 'package:hafiz_app/presentation/khatmah/widgets/today_progress_card.dart';
import 'package:hafiz_app/presentation/khatmah/widgets/streak_card.dart';
import 'package:hafiz_app/presentation/khatmah/widgets/weekly_heatmap.dart';
import 'package:hafiz_app/presentation/khatmah/widgets/dua_khatm_card.dart';
import 'package:hafiz_app/core/notifications/notification_service.dart';
import 'package:intl/intl.dart';

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});

  static Widget builder(BuildContext context) {
    try {
      sl<KhatmahBloc>().add(LoadKhatmahDashboard());
    } catch (e, s) {
      Logger.error('Failed to load KhatmahDashboard: $e\n$s', feature: 'Khatmah');
    }
    return const KhatmahScreen();
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
          unawaited(NotificationService().showStreakMilestone(m));
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
                        TodayProgressCard(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        StreakCard(
                          streak: state.streak,
                          cloudStreak: state.cloudStreak,
                          localStreak: state.localStreak,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _GoalCard(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        WeeklyHeatmap(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        DuaKhatmCard(
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
        heroTag: null,
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



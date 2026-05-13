import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import '../bookmarks/bloc/bookmark_bloc.dart';
import '../khatmah/bloc/khatmah_bloc.dart';
import '../khatmah/bloc/khatmah_event.dart';
import '../khatmah/bloc/khatmah_state.dart';
import '../memorization/bloc/memorization_bloc.dart';
import '../memorization/bloc/memorization_event.dart';
import '../memorization/bloc/memorization_state.dart';
import '../recitation_error/bloc/recitation_error_bloc.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static Widget builder(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<MemorizationBloc>()..add(LoadMemorizationProgress()),
        ),
        BlocProvider(
          create: (context) =>
              sl<KhatmahBloc>()..add(LoadKhatmahDashboard()),
        ),
      ],
      child: const _StatsBody(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _StatsBody();
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('stats_title'.tr)),
      body: MultiBlocBuilder(
        blocs: [
          context.read<BookmarkBloc>(),
          context.read<RecitationErrorBloc>(),
          context.read<MemorizationBloc>(),
          context.read<KhatmahBloc>(),
        ],
        builders: (context) {
          final bookmarkState = context.read<BookmarkBloc>().state;
          final errorState = context.read<RecitationErrorBloc>().state;
          final memState = context.read<MemorizationBloc>().state;
          final khatmahState = context.read<KhatmahBloc>().state;

          final isLoading =
              memState is MemorizationInitial ||
              memState is MemorizationLoading ||
              khatmahState is KhatmahInitial ||
              khatmahState is KhatmahLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (memState is MemorizationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.error.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      memState.message.tr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () => context.read<MemorizationBloc>().add(
                        LoadMemorizationProgress(),
                      ),
                      child: Text('lbl_retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          int bookmarkCount = 0;
          int practiceCount = 0;
          int memorizedCount = 0;
          int inProgressCount = 0;
          int notStartedCount = 0;

          if (bookmarkState is BookmarkLoaded) {
            bookmarkCount = bookmarkState.bookmarks.length;
          }

          if (errorState is RecitationErrorLoaded) {
            practiceCount = errorState.errors.length;
          }

          if (memState is MemorizationLoaded) {
            memorizedCount = memState.totalMemorized;
            inProgressCount = memState.totalInProgress;
            notStartedCount = memState.totalNotStarted;
          }

          int streak = 0;
          int cloudStreak = 0;
          int localStreak = 0;

          if (khatmahState is KhatmahDashboardLoaded) {
            streak = khatmahState.streak;
            cloudStreak = khatmahState.cloudStreak;
            localStreak = khatmahState.localStreak;
          }

          final allZero =
              bookmarkCount == 0 &&
              practiceCount == 0 &&
              memorizedCount == 0 &&
              streak == 0;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<MemorizationBloc>().add(LoadMemorizationProgress());
              context.read<KhatmahBloc>().add(LoadKhatmahDashboard());
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLarge = constraints.maxWidth > 900;
                final horizontalPadding = isLarge ? 32.0 : 16.0;

                Widget content = ListView(
                  padding: EdgeInsets.all(horizontalPadding),
                  children: [
                _StreakCard(
                  streak: streak,
                  cloudStreak: cloudStreak,
                  localStreak: localStreak,
                  isDark: isDark,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _ProgressChart(
                  memorized: memorizedCount,
                  inProgress: inProgressCount,
                  notStarted: notStartedCount,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  context,
                  theme,
                  icon: Icons.bookmark_rounded,
                  label: 'stats_bookmarks'.tr,
                  value: bookmarkCount,
                  color: colors.statBookmark,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  context,
                  theme,
                  icon: Icons.playlist_add_check_rounded,
                  label: 'stats_practice_verses'.tr,
                  value: practiceCount,
                  color: colors.statPractice,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  context,
                  theme,
                  icon: Icons.menu_book_rounded,
                  label: 'stats_surahs_completed'.tr,
                  value: memorizedCount,
                  color: colors.statCompleted,
                ),
                const SizedBox(height: 24),
                if (allZero)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'stats_no_activity'.tr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );

            if (isLarge) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              );
            }

            return content;
          },
        ),
      );
        },
      ),
    );
  }

  static Widget _buildStatCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
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

class _StreakCard extends StatelessWidget {
  final int streak;
  final int cloudStreak;
  final int localStreak;
  final bool isDark;
  final AppColors colors;

  const _StreakCard({
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

class _ProgressChart extends StatelessWidget {
  final int memorized;
  final int inProgress;
  final int notStarted;
  final AppColors colors;

  const _ProgressChart({
    required this.memorized,
    required this.inProgress,
    required this.notStarted,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = 114;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.mushafPageBorder.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, size: 22, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'lbl_quran_progress'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: _StackedBarPainter(
                    memorized: memorized,
                    inProgress: inProgress,
                    notStarted: notStarted,
                    total: total,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    memorizedColor: colors.memorizedStatus,
                    inProgressColor: colors.inProgressStatus,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _LegendDot(color: colors.memorizedStatus, label: 'lbl_memorized'.tr),
                const SizedBox(width: 16),
                _LegendDot(color: colors.inProgressStatus, label: 'lbl_in_progress'.tr),
                const SizedBox(width: 16),
                _LegendDot(color: colors.notStartedStatus, label: 'lbl_not_started'.tr),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _StackedBarPainter extends CustomPainter {
  final int memorized;
  final int inProgress;
  final int notStarted;
  final int total;
  final Color backgroundColor;
  final Color memorizedColor;
  final Color inProgressColor;

  _StackedBarPainter({
    required this.memorized,
    required this.inProgress,
    required this.notStarted,
    required this.total,
    required this.backgroundColor,
    required this.memorizedColor,
    required this.inProgressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, bgPaint);

    final memFrac = total > 0 ? memorized / total : 0.0;
    final progFrac = total > 0 ? inProgress / total : 0.0;

    if (memFrac > 0) {
      final memPaint = Paint()..color = memorizedColor;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          size.width * memFrac,
          size.height,
          topLeft: const Radius.circular(12),
          bottomLeft: const Radius.circular(12),
          topRight: progFrac == 0 && memFrac == 1
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: progFrac == 0 && memFrac == 1
              ? const Radius.circular(12)
              : Radius.zero,
        ),
        memPaint,
      );
    }

    if (progFrac > 0) {
      final progPaint = Paint()..color = inProgressColor;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          size.width * memFrac,
          0,
          size.width * (memFrac + progFrac),
          size.height,
          topLeft: memFrac == 0 ? const Radius.circular(12) : Radius.zero,
          bottomLeft: memFrac == 0 ? const Radius.circular(12) : Radius.zero,
          topRight: (memFrac + progFrac) >= 0.999
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: (memFrac + progFrac) >= 0.999
              ? const Radius.circular(12)
              : Radius.zero,
        ),
        progPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarPainter oldDelegate) {
    return memorized != oldDelegate.memorized ||
        inProgress != oldDelegate.inProgress ||
        notStarted != oldDelegate.notStarted ||
        backgroundColor != oldDelegate.backgroundColor ||
        memorizedColor != oldDelegate.memorizedColor ||
        inProgressColor != oldDelegate.inProgressColor;
  }
}

typedef MultiBlocWidgetBuilder = Widget Function(BuildContext context);

class MultiBlocBuilder extends StatelessWidget {
  final List<StateStreamable> blocs;
  final MultiBlocWidgetBuilder builders;

  const MultiBlocBuilder({
    super.key,
    required this.blocs,
    required this.builders,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = builders(context);
    for (final bloc in blocs) {
      result = BlocBuilder(
        bloc: bloc,
        builder: (context, _) => builders(context),
      );
    }
    return result;
  }
}

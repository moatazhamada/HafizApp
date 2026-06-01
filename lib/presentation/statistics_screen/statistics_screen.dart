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
import '../../widgets/loading_indicator.dart';
import 'widgets/progress_chart.dart';
import 'widgets/streak_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const _StatisticsScreenLoader();
  }

  @override
  Widget build(BuildContext context) {
    return const _StatsBody();
  }
}

class _StatisticsScreenLoader extends StatefulWidget {
  const _StatisticsScreenLoader();

  @override
  State<_StatisticsScreenLoader> createState() => _StatisticsScreenLoaderState();
}

class _StatisticsScreenLoaderState extends State<_StatisticsScreenLoader> {
  MemorizationBloc? _bloc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createBloc();
  }

  void _createBloc() {
    setState(() {
      _error = null;
    });
    try {
      final bloc = sl<MemorizationBloc>()..add(LoadMemorizationProgress());
      setState(() {
        _bloc = bloc;
      });
    } catch (e, s) {
      Logger.error('Failed to create MemorizationBloc: $e\n$s', feature: 'Memorization');
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('stats_title'.tr)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'msg_operation_failed'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: _createBloc,
                  child: Text('lbl_retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    return BlocProvider.value(
      value: bloc,
      child: const _StatsBody(),
    );
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
      body: BlocBuilder<MemorizationBloc, MemorizationState>(
        builder: (context, memState) {
          if (memState is MemorizationInitial || memState is MemorizationLoading) {
            return const LoadingIndicator();
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    _StreakCardWrapper(isDark: isDark, colors: colors),
                    const SizedBox(height: 16),
                    _ProgressChartWrapper(colors: colors),
                    const SizedBox(height: 16),
                    _BookmarkStatWrapper(theme: theme, color: colors.statBookmark),
                    const SizedBox(height: 12),
                    _PracticeStatWrapper(theme: theme, color: colors.statPractice),
                    const SizedBox(height: 12),
                    _CompletedStatWrapper(theme: theme, color: colors.statCompleted),
                    const SizedBox(height: 24),
                    _EmptyStateWrapper(isDark: isDark),
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
}

class _StreakCardWrapper extends StatelessWidget {
  final bool isDark;
  final AppColors colors;

  const _StreakCardWrapper({required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhatmahBloc, KhatmahState>(
      builder: (context, state) {
        int streak = 0;
        int cloudStreak = 0;
        int localStreak = 0;
        if (state is KhatmahDashboardLoaded) {
          streak = state.streak;
          cloudStreak = state.cloudStreak;
          localStreak = state.localStreak;
        }
        return StreakCard(
          streak: streak,
          cloudStreak: cloudStreak,
          localStreak: localStreak,
          isDark: isDark,
          colors: colors,
        );
      },
    );
  }
}

class _ProgressChartWrapper extends StatelessWidget {
  final AppColors colors;

  const _ProgressChartWrapper({required this.colors});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemorizationBloc, MemorizationState>(
      builder: (context, state) {
        int memorized = 0;
        int inProgress = 0;
        int notStarted = 0;
        if (state is MemorizationLoaded) {
          memorized = state.totalMemorized;
          inProgress = state.totalInProgress;
          notStarted = state.totalNotStarted;
        }
        return ProgressChart(
          memorized: memorized,
          inProgress: inProgress,
          notStarted: notStarted,
          colors: colors,
        );
      },
    );
  }
}

class _BookmarkStatWrapper extends StatelessWidget {
  final ThemeData theme;
  final Color color;

  const _BookmarkStatWrapper({required this.theme, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {
        final count = state is BookmarkLoaded ? state.bookmarks.length : 0;
        return _StatCard(
          theme: theme,
          icon: Icons.bookmark_rounded,
          label: 'stats_bookmarks'.tr,
          value: count,
          color: color,
        );
      },
    );
  }
}

class _PracticeStatWrapper extends StatelessWidget {
  final ThemeData theme;
  final Color color;

  const _PracticeStatWrapper({required this.theme, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecitationErrorBloc, RecitationErrorState>(
      builder: (context, state) {
        final count = state is RecitationErrorLoaded ? state.errors.length : 0;
        return _StatCard(
          theme: theme,
          icon: Icons.playlist_add_check_rounded,
          label: 'stats_practice_verses'.tr,
          value: count,
          color: color,
        );
      },
    );
  }
}

class _CompletedStatWrapper extends StatelessWidget {
  final ThemeData theme;
  final Color color;

  const _CompletedStatWrapper({required this.theme, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemorizationBloc, MemorizationState>(
      builder: (context, state) {
        final count = state is MemorizationLoaded ? state.totalMemorized : 0;
        return _StatCard(
          theme: theme,
          icon: Icons.menu_book_rounded,
          label: 'stats_surahs_completed'.tr,
          value: count,
          color: color,
        );
      },
    );
  }
}

class _EmptyStateWrapper extends StatelessWidget {
  final bool isDark;

  const _EmptyStateWrapper({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhatmahBloc, KhatmahState>(
      buildWhen: (previous, current) =>
          current is KhatmahDashboardLoaded || current is KhatmahInitial,
      builder: (context, khatmahState) {
        return BlocBuilder<MemorizationBloc, MemorizationState>(
          buildWhen: (previous, current) => current is MemorizationLoaded,
          builder: (context, memState) {
            return BlocBuilder<BookmarkBloc, BookmarkState>(
              buildWhen: (previous, current) => current is BookmarkLoaded,
              builder: (context, bookmarkState) {
                return BlocBuilder<RecitationErrorBloc, RecitationErrorState>(
                  buildWhen: (previous, current) =>
                      current is RecitationErrorLoaded,
                  builder: (context, errorState) {
                    final bookmarkCount = bookmarkState is BookmarkLoaded
                        ? bookmarkState.bookmarks.length
                        : 0;
                    final practiceCount = errorState is RecitationErrorLoaded
                        ? errorState.errors.length
                        : 0;
                    final memorizedCount = memState is MemorizationLoaded
                        ? memState.totalMemorized
                        : 0;
                    final streak = khatmahState is KhatmahDashboardLoaded
                        ? khatmahState.streak
                        : 0;

                    final allZero = bookmarkCount == 0 &&
                        practiceCount == 0 &&
                        memorizedCount == 0 &&
                        streak == 0;

                    if (!allZero) return const SizedBox.shrink();

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'stats_no_activity'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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

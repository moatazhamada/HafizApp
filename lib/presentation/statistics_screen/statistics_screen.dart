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
                StreakCard(
                  streak: streak,
                  cloudStreak: cloudStreak,
                  localStreak: localStreak,
                  isDark: isDark,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                ProgressChart(
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

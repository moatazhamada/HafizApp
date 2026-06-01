import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../injection_container.dart';
import '../../bookmarks/bloc/bookmark_bloc.dart';
import '../../khatmah/bloc/khatmah_bloc.dart';

import '../../khatmah/bloc/khatmah_state.dart';
import '../../memorization/bloc/memorization_bloc.dart';
import '../../memorization/bloc/memorization_event.dart';
import '../../memorization/bloc/memorization_state.dart';
import '../../recitation_error/bloc/recitation_error_bloc.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/activity_heatmap.dart';
import '../../../widgets/error_state.dart';
import '../widgets/reading_session_insights.dart';
import 'student_surface/widgets/compact_surah_tile.dart';
import 'student_surface/widgets/memorization_card.dart';
import 'student_surface/widgets/stat_pill.dart';
import 'student_surface/widgets/streak_card.dart';

class StudentSurface extends StatelessWidget {
  const StudentSurface({super.key});

  @override
  Widget build(BuildContext context) {
    MemorizationBloc? bloc;
    try {
      bloc = sl<MemorizationBloc>()..add(LoadMemorizationProgress());
    } catch (e, s) {
      Logger.error('Failed to create MemorizationBloc: $e\n$s', feature: 'Memorization');
    }
    if (bloc == null) {
      return Scaffold(
        appBar: AppBar(title: Text('lbl_home'.tr)),
        body: ErrorState(
          message: 'msg_data_load_error'.tr,
          onRetry: () {
            // Trigger a rebuild to retry bloc creation
            // ignore: invalid_use_of_protected_member
            (context as Element).markNeedsBuild();
          },
        ),
      );
    }
    return BlocProvider.value(
      value: bloc,
      child: const _StudentBody(),
    );
  }
}

class _StudentBody extends StatefulWidget {
  const _StudentBody();

  @override
  State<_StudentBody> createState() => _StudentBodyState();
}

class _StudentBodyState extends State<_StudentBody> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Dashboard Cards
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Memorization Progress Card
              SliverToBoxAdapter(
                child: BlocBuilder<MemorizationBloc, MemorizationState>(
                  buildWhen: (p, c) => c is MemorizationLoaded || c is MemorizationError,
                  builder: (context, memState) {
                    if (memState is MemorizationLoaded) {
                      return MemorizationCard(state: memState);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStatsRow(context),
                ),
              ),

              // Khatmah Streak
              SliverToBoxAdapter(
                child: BlocBuilder<KhatmahBloc, KhatmahState>(
                  buildWhen: (previous, current) {
                    if (previous is KhatmahDashboardLoaded && current is KhatmahDashboardLoaded) {
                      return previous.streak != current.streak;
                    }
                    return previous != current;
                  },
                  builder: (context, khatmahState) {
                    if (khatmahState is KhatmahDashboardLoaded &&
                        khatmahState.streak > 0) {
                      return StreakCard(streak: khatmahState.streak);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Activity Heatmap
              SliverToBoxAdapter(
                child: BlocBuilder<KhatmahBloc, KhatmahState>(
                  buildWhen: (previous, current) {
                    if (previous is KhatmahDashboardLoaded && current is KhatmahDashboardLoaded) {
                      return previous.recentLogs != current.recentLogs;
                    }
                    return previous != current;
                  },
                  builder: (context, khatmahState) {
                    if (khatmahState is KhatmahDashboardLoaded &&
                        khatmahState.recentLogs.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ActivityHeatmap(
                          logs: khatmahState.recentLogs,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Reading Session Insights
              SliverToBoxAdapter(
                child: BlocBuilder<KhatmahBloc, KhatmahState>(
                  buildWhen: (previous, current) {
                    if (previous is KhatmahDashboardLoaded && current is KhatmahDashboardLoaded) {
                      return previous.recentLogs != current.recentLogs;
                    }
                    return previous != current;
                  },
                  builder: (context, khatmahState) {
                    if (khatmahState is KhatmahDashboardLoaded &&
                        khatmahState.recentLogs.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ReadingSessionInsights(
                          recentLogs: khatmahState.recentLogs,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'lbl_surah'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Compact Surah List
              SliverList.builder(
                itemCount: QuranIndex.quranSurahs.length,
                itemBuilder: (context, index) {
                  final surah = QuranIndex.quranSurahs[index];
                  return StaggeredSliverListItem(
                    index: index,
                    child: CompactSurahTile(surah: surah),
                  );
                },
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MemorizedStat()),
        SizedBox(width: 8),
        Expanded(child: _InProgressStat()),
        SizedBox(width: 8),
        Expanded(child: _BookmarksStat()),
        SizedBox(width: 8),
        Expanded(child: _PracticeStat()),
      ],
    );
  }
}

class _MemorizedStat extends StatelessWidget {
  const _MemorizedStat();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemorizationBloc, MemorizationState>(
      buildWhen: (p, c) => c is MemorizationLoaded,
      builder: (context, state) {
        final value = state is MemorizationLoaded ? state.totalMemorized : 0;
        return StatPill(
          label: 'lbl_memorized'.tr,
          value: value,
          color: AppColors.of(context).memorizedStatus,
        );
      },
    );
  }
}

class _InProgressStat extends StatelessWidget {
  const _InProgressStat();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemorizationBloc, MemorizationState>(
      buildWhen: (p, c) => c is MemorizationLoaded,
      builder: (context, state) {
        final value = state is MemorizationLoaded ? state.totalInProgress : 0;
        return StatPill(
          label: 'lbl_in_progress'.tr,
          value: value,
          color: AppColors.of(context).inProgressStatus,
        );
      },
    );
  }
}

class _BookmarksStat extends StatelessWidget {
  const _BookmarksStat();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      buildWhen: (p, c) => c is BookmarkLoaded,
      builder: (context, state) {
        final value = state is BookmarkLoaded ? state.bookmarks.length : 0;
        return StatPill(
          label: 'lbl_bookmarks'.tr,
          value: value,
          color: AppColors.of(context).statBookmark,
        );
      },
    );
  }
}

class _PracticeStat extends StatelessWidget {
  const _PracticeStat();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecitationErrorBloc, RecitationErrorState>(
      buildWhen: (p, c) => c is RecitationErrorLoaded,
      builder: (context, state) {
        final value = state is RecitationErrorLoaded ? state.errors.length : 0;
        return StatPill(
          label: 'lbl_practice_list'.tr,
          value: value,
          color: AppColors.of(context).statPractice,
        );
      },
    );
  }
}

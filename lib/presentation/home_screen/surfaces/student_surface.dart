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
    return BlocBuilder<MemorizationBloc, MemorizationState>(
      builder: (context, memState) {
        return BlocBuilder<BookmarkBloc, BookmarkState>(
          builder: (context, bookmarkState) {
            return BlocBuilder<RecitationErrorBloc, RecitationErrorState>(
              builder: (context, errorState) {
                int memorized = 0;
                int inProgress = 0;
                int bookmarks = 0;
                int practice = 0;

                if (memState is MemorizationLoaded) {
                  memorized = memState.totalMemorized;
                  inProgress = memState.totalInProgress;
                }
                if (bookmarkState is BookmarkLoaded) {
                  bookmarks = bookmarkState.bookmarks.length;
                }
                if (errorState is RecitationErrorLoaded) {
                  practice = errorState.errors.length;
                }

                return Row(
                  children: [
                    Expanded(
                      child: StatPill(
                        label: 'lbl_memorized'.tr,
                        value: memorized,
                        color: AppColors.of(context).memorizedStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatPill(
                        label: 'lbl_in_progress'.tr,
                        value: inProgress,
                        color: AppColors.of(context).inProgressStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatPill(
                        label: 'lbl_bookmarks'.tr,
                        value: bookmarks,
                        color: AppColors.of(context).statBookmark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatPill(
                        label: 'lbl_practice_list'.tr,
                        value: practice,
                        color: AppColors.of(context).statPractice,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

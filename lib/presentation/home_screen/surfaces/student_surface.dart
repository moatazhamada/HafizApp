import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/tracking/behavior_tracker.dart';
import '../../../core/theme/app_colors.dart';
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
import '../widgets/reading_session_insights.dart';


class StudentSurface extends StatelessWidget {
  const StudentSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<MemorizationBloc>()..add(LoadMemorizationProgress()),
        ),
        BlocProvider.value(value: sl<KhatmahBloc>()),
      ],
      child: const _StudentBody(),
    );
  }
}

class _StudentBody extends StatelessWidget {
  const _StudentBody();

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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSearchBar(context),
                ),
              ),

              // Memorization Progress Card
              SliverToBoxAdapter(
                child: BlocBuilder<MemorizationBloc, MemorizationState>(
                  builder: (context, memState) {
                    if (memState is MemorizationLoaded) {
                      return _MemorizationCard(state: memState);
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
                  builder: (context, khatmahState) {
                    if (khatmahState is KhatmahDashboardLoaded &&
                        khatmahState.streak > 0) {
                      return _StreakCard(streak: khatmahState.streak);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Activity Heatmap
              SliverToBoxAdapter(
                child: BlocBuilder<KhatmahBloc, KhatmahState>(
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
                    child: _CompactSurahTile(surah: surah),
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

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      textDirection: TextDirection.ltr,
      readOnly: true,
      onTap: () => NavigatorService.pushNamed(AppRoutes.searchPage),
      decoration: InputDecoration(
        hintText: 'lbl_search_surah'.tr,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
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
                      child: _StatPill(
                        label: 'lbl_memorized'.tr,
                        value: memorized,
                        color: AppColors.of(context).memorizedStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: 'lbl_in_progress'.tr,
                        value: inProgress,
                        color: AppColors.of(context).inProgressStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: 'lbl_bookmarks'.tr,
                        value: bookmarks,
                        color: AppColors.of(context).statBookmark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
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

class _MemorizationCard extends StatelessWidget {
  final MemorizationLoaded state;

  const _MemorizationCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = 114;
    final memorized = state.totalMemorized;
    final inProgress = state.totalInProgress;
    final notStarted = state.totalNotStarted;

    final memFrac = total > 0 ? memorized / total : 0.0;
    final progFrac = total > 0 ? inProgress / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'lbl_memorization'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'lbl_semantics_memorization_progress'
                    .tr
                    .replaceAll('{percent}', '${((memorized / total) * 100).round()}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (memFrac * 100).round(),
                          child: Container(color: AppColors.of(context).memorizedStatus),
                        ),
                        Expanded(
                          flex: (progFrac * 100).round(),
                          child: Container(color: AppColors.of(context).inProgressStatus),
                        ),
                        Expanded(
                          flex: (notStarted / total * 100).round(),
                          child: Container(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LegendItem(color: AppColors.of(context).memorizedStatus, label: '$memorized'),
                  _LegendItem(color: AppColors.of(context).inProgressStatus, label: '$inProgress'),
                  _LegendItem(color: AppColors.of(context).notStartedStatus, label: '$notStarted'),
                ],
              ),
              if (state.dueReviews.isNotEmpty) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    BehaviorTracker.recordSession('memorize');
                    NavigatorService.pushNamed(AppRoutes.memorizationPage);
                  },
                  child: Text(
                    '${'lbl_review'.tr} (${state.dueReviews.length})',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: AppColors.of(context).inProgressStatus.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.of(context).inProgressStatus.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.of(context).inProgressStatus.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: streak > 0 ? AppColors.of(context).inProgressStatus : AppColors.of(context).notStartedStatus,
                  size: 28,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$streak ${'lbl_day_streak'.tr}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: streak > 0 ? AppColors.of(context).inProgressStatus : AppColors.of(context).notStartedStatus,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CompactSurahTile extends StatelessWidget {
  final Surah surah;

  const _CompactSurahTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Semantics(
      button: true,
      label:
          '${surah.nameEnglish}, ${surah.nameArabic}, ${'lbl_surah'.tr} ${surah.id}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            PrefUtils().saveLastReadSurah(surah);
            final defaultView = PrefUtils().getDefaultQuranView();
            if (defaultView == 'mushaf') {
              NavigatorService.pushNamed(AppRoutes.mushafScreen);
            } else {
              NavigatorService.pushNamed(AppRoutes.surahPage, arguments: surah);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${surah.id}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isArabic) ...[
                  Expanded(
                    child: Text(
                      surah.nameEnglish,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'NotoNaskhArabic',
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

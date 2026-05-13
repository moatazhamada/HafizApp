import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/tajweed/tajweed_models.dart';
import 'package:hafiz_app/injection_container.dart';
import 'bloc/tajweed_roadmap_bloc.dart';

class TajweedRoadmapScreen extends StatelessWidget {
  const TajweedRoadmapScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TajweedRoadmapBloc>()..add(const LoadTajweedRoadmap()),
      child: const TajweedRoadmapScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_tajweed_roadmap'.tr)),
      body: BlocBuilder<TajweedRoadmapBloc, TajweedRoadmapState>(
        builder: (context, state) {
          if (state is TajweedRoadmapLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TajweedRoadmapError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<TajweedRoadmapBloc>()
                        .add(const LoadTajweedRoadmap()),
                    child: Text('lbl_retry'.tr),
                  ),
                ],
              ),
            );
          }
          if (state is TajweedRoadmapLoaded) {
            if (!state.progress.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'lbl_no_tajweed_data'.tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TajweedRoadmapBloc>()
                    .add(const LoadTajweedRoadmap());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AccuracyCard(progress: state.progress),
                  const SizedBox(height: 16),
                  if (state.progress.weakAreas.isNotEmpty) ...[
                    Text(
                      'lbl_weak_areas'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.progress.weakAreas.map(
                      (w) => _WeaknessCard(weakness: w),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.practiceItems.isNotEmpty) ...[
                    Text(
                      'lbl_suggested_practice'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.practiceItems.map(
                      (item) => _PracticeItemCard(item: item),
                    ),
                  ],
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

class _AccuracyCard extends StatelessWidget {
  final TajweedProgress progress;
  const _AccuracyCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pct = (progress.overallAccuracy * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq, color: colors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'lbl_tajweed_accuracy'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress.overallAccuracy,
                    strokeWidth: 10,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 80
                          ? AppColors.of(context).memorizedStatus
                          : pct >= 50
                          ? AppColors.of(context).inProgressStatus
                          : AppColors.of(context).needsReviewStatus,
                    ),
                  ),
                ),
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${progress.totalSessions} sessions • ${progress.totalMistakes} mistakes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeaknessCard extends StatelessWidget {
  final TajweedWeakness weakness;
  const _WeaknessCard({required this.weakness});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accuracyPct = (weakness.accuracy * 100).round();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.of(context).inProgressStatus.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.of(context).inProgressStatus.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${weakness.errorCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).warning,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weakness.ruleName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$accuracyPct% accuracy',
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

class _PracticeItemCard extends StatelessWidget {
  final TajweedPracticeItem item;
  const _PracticeItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(Icons.school, color: colors.primary),
        title: Text(item.verseKey),
        subtitle: Text(
          '${item.ruleName} — ${item.reason}',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 18),
          onPressed: () {
            final parts = item.verseKey.split(':');
            if (parts.length == 2) {
              NavigatorService.pushNamed(
                AppRoutes.verseStudyScreen,
                arguments: {'verseKey': item.verseKey},
              );
            }
          },
        ),
      ),
    );
  }
}

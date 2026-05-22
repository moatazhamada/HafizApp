import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../../../core/app_export.dart';
import '../../../../../../core/tracking/behavior_tracker.dart';
import '../../../../memorization/bloc/memorization_state.dart';
import 'legend_item.dart';

class MemorizationCard extends StatelessWidget {
  final MemorizationLoaded state;

  const MemorizationCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = 114;
    final memorized = state.totalMemorized;
    final inProgress = state.totalInProgress;
    final notStarted = state.totalNotStarted;

    final memFrac = total > 0 ? memorized / total : 0.0;
    final progFrac = total > 0 ? inProgress / total : 0.0;

    final memFlex = math.max(1, (memFrac * 100).round());
    final progFlex = math.max(1, (progFrac * 100).round());
    final notStartedFlex = math.max(1, (notStarted / total * 100).round());

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
                          flex: memFlex,
                          child: Container(color: AppColors.of(context).memorizedStatus),
                        ),
                        Expanded(
                          flex: progFlex,
                          child: Container(color: AppColors.of(context).inProgressStatus),
                        ),
                        Expanded(
                          flex: notStartedFlex,
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
                  LegendItem(color: AppColors.of(context).memorizedStatus, label: '$memorized'),
                  LegendItem(color: AppColors.of(context).inProgressStatus, label: '$inProgress'),
                  LegendItem(color: AppColors.of(context).notStartedStatus, label: '$notStarted'),
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

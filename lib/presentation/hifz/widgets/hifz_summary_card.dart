import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_state.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_stat_chip.dart';

class HifzSummaryCard extends StatelessWidget {
  final HifzLoaded state;

  const HifzSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "${'lbl_hifz_progress'.tr}: ${state.masteredCount}/${state.totalEntries}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.totalEntries > 0
                    ? state.masteredCount / state.totalEntries
                    : 0,
                minHeight: 12,
                backgroundColor: AppColors.of(context).notStartedStatus,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.of(context).primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HifzStatChip(
                  label: 'lbl_new'.tr,
                  value: state.newLessons.length,
                  color: AppColors.of(context).inProgressStatus,
                ),
                HifzStatChip(
                  label: 'lbl_solid'.tr,
                  value: state.solid.length,
                  color: AppColors.of(context).memorizedStatus,
                ),
                HifzStatChip(
                  label: 'lbl_weak'.tr,
                  value: state.weak.length,
                  color: AppColors.of(context).needsReviewStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

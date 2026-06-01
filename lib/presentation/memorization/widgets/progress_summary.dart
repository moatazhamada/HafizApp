import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_state.dart';
import 'stat_chip.dart';

class ProgressSummary extends StatelessWidget {
  final MemorizationLoaded state;
  final bool isDark;

  const ProgressSummary({
    super.key,
    required this.state,
    required this.isDark,
  });

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
              '${'lbl_quran_progress'.tr}: ${state.totalMemorized}/114',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'lbl_semantics_memorization_progress'
                  .tr
                  .replaceAll('{percent}', '${((state.totalMemorized / 114) * 100).round()}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.totalMemorized / 114,
                  minHeight: 12,
                  backgroundColor: AppColors.of(context).notStartedStatus,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.of(context).primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatChip(
                  label: 'lbl_memorized'.tr,
                  value: state.totalMemorized,
                  color: AppColors.of(context).memorizedStatus,
                ),
                StatChip(
                  label: 'lbl_in_progress'.tr,
                  value: state.totalInProgress,
                  color: AppColors.of(context).inProgressStatus,
                ),
                StatChip(
                  label: 'lbl_not_started'.tr,
                  value: state.totalNotStarted,
                  color: AppColors.of(context).notStartedStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import 'legend_dot.dart';
import 'stacked_bar_painter.dart';

class ProgressChart extends StatelessWidget {
  final int memorized;
  final int inProgress;
  final int notStarted;
  final AppColors colors;

  const ProgressChart({
    super.key,
    required this.memorized,
    required this.inProgress,
    required this.notStarted,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const total = 114;
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
                  painter: StackedBarPainter(
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
                LegendDot(color: colors.memorizedStatus, label: 'lbl_memorized'.tr),
                const SizedBox(width: 16),
                LegendDot(color: colors.inProgressStatus, label: 'lbl_in_progress'.tr),
                const SizedBox(width: 16),
                LegendDot(color: colors.notStartedStatus, label: 'lbl_not_started'.tr),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_event.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_state.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<MemorizationBloc>()..add(LoadMemorizationProgress()),
      child: const MemorizationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PrefUtils().getIsDarkMode() == true;
    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_memorization'.tr),
        backgroundColor: const Color(0xFF006754),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<MemorizationBloc, MemorizationState>(
        builder: (context, state) {
          if (state is MemorizationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MemorizationError) {
            return Center(child: Text(state.message));
          }
          if (state is MemorizationLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MemorizationBloc>().add(
                  LoadMemorizationProgress(),
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProgressSummary(state: state, isDark: isDark),
                  const SizedBox(height: 24),
                  if (state.dueReviews.isNotEmpty) ...[
                    Text(
                      'lbl_due_for_review'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.dueReviews.map(
                      (p) => _ReviewCard(progress: p, isDark: isDark),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'lbl_all_surahs'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.allProgress.map(
                    (p) => _SurahProgressCard(progress: p, isDark: isDark),
                  ),
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

class _ProgressSummary extends StatelessWidget {
  final MemorizationLoaded state;
  final bool isDark;

  const _ProgressSummary({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.totalMemorized / 114,
                minHeight: 12,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF006754),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'lbl_memorized'.tr,
                  value: state.totalMemorized,
                  color: Colors.green,
                ),
                _StatChip(
                  label: 'lbl_in_progress'.tr,
                  value: state.totalInProgress,
                  color: Colors.orange,
                ),
                _StatChip(
                  label: 'lbl_not_started'.tr,
                  value: state.totalNotStarted,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final MemorizationProgress progress;
  final bool isDark;

  const _ReviewCard({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.orange),
        title: Text(progress.surahName),
        subtitle: Text(
          '${'lbl_best_score'.tr}: ${progress.bestScore.toStringAsFixed(0)}%',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow, color: Color(0xFF006754)),
          onPressed: () {
            final surah = QuranIndex.quranSurahs.firstWhere(
              (s) => s.id == progress.surahId,
              orElse: () => Surah(progress.surahId, '', ''),
            );
            NavigatorService.popAndPushNamed(
              AppRoutes.surahPage,
              arguments: {'surah': surah},
            );
          },
        ),
      ),
    );
  }
}

class _SurahProgressCard extends StatelessWidget {
  final MemorizationProgress progress;
  final bool isDark;

  const _SurahProgressCard({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(progress.status);
    final statusLabel = _statusLabel(progress.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withValues(alpha: 0.15),
          ),
          alignment: Alignment.center,
          child: Text(
            '${progress.surahId}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        title: Text(
          progress.surahName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '$statusLabel • ${'lbl_best_score'.tr}: ${progress.bestScore.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: progress.status == MemorizationStatus.memorized
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  Color _statusColor(MemorizationStatus status) {
    switch (status) {
      case MemorizationStatus.memorized:
        return Colors.green;
      case MemorizationStatus.inProgress:
        return Colors.orange;
      case MemorizationStatus.needsReview:
        return Colors.red;
      case MemorizationStatus.notStarted:
        return Colors.grey;
    }
  }

  String _statusLabel(MemorizationStatus status) {
    switch (status) {
      case MemorizationStatus.memorized:
        return 'lbl_memorized'.tr;
      case MemorizationStatus.inProgress:
        return 'lbl_in_progress'.tr;
      case MemorizationStatus.needsReview:
        return 'lbl_needs_review'.tr;
      case MemorizationStatus.notStarted:
        return 'lbl_not_started'.tr;
    }
  }
}

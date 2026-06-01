import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_bloc.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_event.dart';
import 'package:hafiz_app/presentation/memorization/bloc/memorization_state.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_indicator.dart';
import 'package:hafiz_app/core/utils/bottom_sheet_utils.dart';
import 'widgets/progress_summary.dart';
import 'widgets/review_card.dart';
import 'widgets/start_tracking_sheet.dart';
import 'widgets/surah_progress_card.dart';

class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  static Widget builder(BuildContext context) {
    MemorizationBloc? bloc;
    try {
      bloc = sl<MemorizationBloc>()..add(LoadMemorizationProgress());
    } catch (e, s) {
      Logger.error('Failed to create MemorizationBloc: $e\n$s', feature: 'Memorization');
    }
    if (bloc == null) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }
    return BlocProvider.value(
      value: bloc,
      child: const MemorizationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_memorization'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'lbl_help'.tr,
            onPressed: () {
              unawaited(
                sl<AnalyticsService>().logHelpOpened(feature: 'memorization'),
              );
              _showHelpSheet(context);
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<MemorizationBloc, MemorizationState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType ||
            (previous is MemorizationLoaded &&
                current is MemorizationLoaded &&
                previous.allProgress.isNotEmpty != current.allProgress.isNotEmpty),
        builder: (context, state) {
          if (state is MemorizationLoaded && state.allProgress.isNotEmpty) {
            return FloatingActionButton(
              heroTag: null,
              onPressed: () => _showStartTrackingSheet(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<MemorizationBloc, MemorizationState>(
        builder: (context, state) {
          if (state is MemorizationLoading) {
            return const LoadingIndicator();
          }
          if (state is MemorizationError) {
            return ErrorState(
              message: state.message.tr,
              onRetry: () => context.read<MemorizationBloc>().add(
                LoadMemorizationProgress(),
              ),
            );
          }
          if (state is MemorizationLoaded) {
            if (state.allProgress.isEmpty) {
              return EmptyState(
                icon: Icons.school_outlined,
                message: 'lbl_memorization_empty_title'.tr,
                subtitle: 'lbl_memorization_empty_subtitle'.tr,
                actionLabel: 'lbl_start_tracking'.tr,
                actionIcon: Icons.play_arrow,
                onAction: () => _showStartTrackingSheet(context),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MemorizationBloc>().add(
                  LoadMemorizationProgress(),
                );
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: ProgressSummary(state: state, isDark: isDark),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                  if (state.dueReviews.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'lbl_due_for_review'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: state.dueReviews.length,
                        itemBuilder: (context, index) {
                          final p = state.dueReviews[index];
                          return ReviewCard(
                            progress: p,
                            isDark: isDark,
                            onLogReview: () => _showReviewDialog(
                              context,
                              surahId: p.surahId,
                              surahName: p.surahName,
                            ),
                            onRead: () {
                              final surah = QuranIndex.quranSurahs.firstWhere(
                                (s) => s.id == p.surahId,
                                orElse: () => Surah(p.surahId, '', ''),
                              );
                              NavigatorService.popAndPushNamed(
                                AppRoutes.surahPage,
                                arguments: {'surah': surah},
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'lbl_all_surahs'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    sliver: SliverList.builder(
                      itemCount: state.allProgress.length,
                      itemBuilder: (context, index) {
                        final p = state.allProgress[index];
                        return SurahProgressCard(
                          progress: p,
                          isDark: isDark,
                          onLogReview: () => _showReviewDialog(
                            context,
                            surahId: p.surahId,
                            surahName: p.surahName,
                          ),
                          onRead: () {
                            final surah = QuranIndex.quranSurahs.firstWhere(
                              (s) => s.id == p.surahId,
                              orElse: () => Surah(p.surahId, '', ''),
                            );
                            NavigatorService.popAndPushNamed(
                              AppRoutes.surahPage,
                              arguments: {'surah': surah},
                            );
                          },
                        );
                      },
                    ),
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

  static void _showStartTrackingSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.7,
      minSize: 0.5,
      maxSize: 0.9,
      builder: (sheetContext, scrollController) => StartTrackingSheet(
        scrollController: scrollController!,
        onSurahSelected: (surahId) {
          Navigator.pop(sheetContext);
          context.read<MemorizationBloc>().add(
            RecordReview(surahId: surahId, score: 100),
          );
          SnackBarHelper.show(
            context,
            message: 'msg_surah_marked_memorized'.tr,
            type: SnackBarType.success,
            duration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  static void _showHelpSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.6,
      minSize: 0.4,
      maxSize: 0.8,
      builder: (ctx, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'memorization_help_title'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'memorization_help_desc'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('lbl_got_it'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showReviewDialog(
    BuildContext context, {
    required int surahId,
    required String surahName,
  }) {
    unawaited(
      sl<AnalyticsService>().logReviewStarted(surahId: surahId),
    );
    final scores = [
      (label: 'btn_perfect'.tr, score: 100.0, color: Colors.green),
      (label: 'btn_hesitant'.tr, score: 85.0, color: Colors.lightGreen),
      (label: 'btn_difficult'.tr, score: 70.0, color: Colors.orange),
      (label: 'btn_hard'.tr, score: 55.0, color: Colors.deepOrange),
      (label: 'btn_failed'.tr, score: 20.0, color: Colors.red),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('dlg_review_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              surahName,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...scores.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: s.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(
                      sl<AnalyticsService>().logReviewCompleted(
                        surahId: surahId,
                        score: s.score.round(),
                      ),
                    );
                    context.read<MemorizationBloc>().add(
                      RecordReview(surahId: surahId, score: s.score),
                    );
                    SnackBarHelper.show(
                      context,
                      message: 'msg_review_logged'.tr,
                      type: SnackBarType.success,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: Text(s.label),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('lbl_cancel'.tr),
          ),
        ],
      ),
    );
  }
}

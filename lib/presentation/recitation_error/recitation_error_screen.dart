import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../widgets/skeleton_loader.dart';

class RecitationErrorScreen extends StatelessWidget {
  const RecitationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('lbl_practice_list'.tr), centerTitle: true),
      body: BlocConsumer<RecitationErrorBloc, RecitationErrorState>(
        listener: (context, state) {
          if (state is RecitationErrorLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!.tr)));
          }
        },
        builder: (context, state) {
          if (state is RecitationErrorLoading) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonListItem(),
            );
          } else if (state is RecitationErrorLoaded) {
            if (state.errors.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: state.errors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final error = state.errors[index];
                final surah = QuranIndex.quranSurahs.firstWhere(
                  (e) => e.id == error.surahId,
                  orElse: () => QuranIndex.quranSurahs[0],
                );

                return Dismissible(
                  key: Key('${error.surahId}_${error.verseId}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('msg_removed_practice'.tr)),
                    );
                    context.read<RecitationErrorBloc>().add(
                      RemoveRecitationErrorEvent(error.surahId, error.verseId),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        NavigatorService.pushNamed(
                          AppRoutes.surahPage,
                          arguments: {
                            'surah': surah,
                            'verseIndex': error.verseId - 1,
                            'resume': true,
                          },
                        ).then((_) {
                          if (context.mounted) {
                            context.read<RecitationErrorBloc>().add(
                              const LoadRecitationErrorsEvent(),
                            );
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    surah.localizedName(context),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${'lbl_verse_num'.tr} ${error.verseId.toLocalizedNumber(context)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                context.read<RecitationErrorBloc>().add(
                                  RemoveRecitationErrorEvent(
                                    error.surahId,
                                    error.verseId,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is RecitationErrorError) {
            return Center(child: Text('${'lbl_error'.tr}: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'msg_no_practice_items'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_practice_hint'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

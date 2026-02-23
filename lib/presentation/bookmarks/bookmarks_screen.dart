import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/bookmark_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../widgets/skeleton_loader.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('lbl_bookmarks'.tr), centerTitle: true),
      body: BlocConsumer<BookmarkBloc, BookmarkState>(
        listener: (context, state) {
          if (state is BookmarkLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!.tr)));
          } else if (state is BookmarkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${"msg_error_prefix".tr}${state.message}'),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonListItem(),
            );
          } else if (state is BookmarkLoaded) {
            if (state.bookmarks.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: state.bookmarks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bookmark = state.bookmarks[index];
                final surah = QuranIndex.quranSurahs.firstWhere(
                  (e) => e.id == bookmark.surahId,
                  orElse: () => QuranIndex.quranSurahs[0],
                );
                final bookmarkBloc = context.read<BookmarkBloc>();

                return Semantics(
                  button: true,
                  label:
                      '${surah.localizedName(context)}, ${'lbl_verse_num'.tr} ${bookmark.verseNumber}. ${'msg_swipe_delete'.tr}',
                  child: Dismissible(
                    key: Key('${bookmark.surahId}_${bookmark.verseNumber}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      bookmarkBloc.add(
                        RemoveBookmarkEvent(
                          bookmark.surahId,
                          bookmark.verseNumber,
                        ),
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
                              'verseIndex': bookmark.verseNumber - 1,
                              'resume': true,
                            },
                          ).then((_) {
                            if (context.mounted) {
                              context.read<BookmarkBloc>().add(
                                const LoadBookmarksEvent(),
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
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bookmark,
                                  color: colorScheme.primary,
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${'lbl_verse_num'.tr} ${bookmark.verseNumber.toLocalizedNumber(context)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                onPressed: () {
                                  bookmarkBloc.add(
                                    RemoveBookmarkEvent(
                                      bookmark.surahId,
                                      bookmark.verseNumber,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is BookmarkError) {
            return Center(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${'lbl_error'.tr}: ${state.message}',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
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
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'msg_no_bookmarks'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'msg_bookmarks_hint'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    NavigatorService.pushNamed(AppRoutes.homeScreen),
                icon: const Icon(Icons.menu_book),
                label: Text('lbl_surah'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

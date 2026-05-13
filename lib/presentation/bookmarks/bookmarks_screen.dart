import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import '../../core/app_export.dart';
import 'bloc/bookmark_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/rtl_utils.dart';
import '../../core/utils/surah_name_formatter.dart';
import '../../widgets/shimmer_loading.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'lbl_back'.tr,
          child: IconButton(
            icon: Icon(rtlBackArrow(context)),
            onPressed: () => NavigatorService.goBack(),
            tooltip: 'lbl_back'.tr,
          ),
        ),
        centerTitle: true,
        title: Semantics(
          header: true,
          child: Text('lbl_bookmarks'.tr, style: AppTextStyles.headingMedium),
        ),
      ),
      body: BlocConsumer<BookmarkBloc, BookmarkState>(
        listener: (context, state) {
          if (state is BookmarkLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!.tr)));
          } else if (state is BookmarkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${"msg_error_prefix".tr}${state.message.tr}'),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const ShimmerLoadingList();
          } else if (state is BookmarkLoaded) {
            if (state.bookmarks.isEmpty) {
              return Center(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.bookmark_outline,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'msg_no_bookmarks'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BookmarkBloc>().add(const LoadBookmarksEvent());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: state.bookmarks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
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
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            NavigatorService.pushNamed(
                              AppRoutes.surahPage,
                              arguments: {
                                'surah': surah,
                                'verseIndex': bookmark.verseNumber - 1,
                              },
                            ).then((_) {
                              // Refresh list when returning from Surah page
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
                                ExcludeSemantics(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.of(
                                        context,
                                      ).primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.bookmark,
                                      color: AppColors.of(context).primary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        surah.localizedName(context),
                                        textDirection: TextDirection.rtl,
                                        style: AppTextStyles.headingSmall
                                            .copyWith(
                                              color: AppColors.of(
                                                context,
                                              ).onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${'lbl_verse_num'.tr} ${bookmark.verseNumber.toLocalizedNumber(context)}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'lbl_delete'.tr,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      bookmarkBloc.add(
                                        RemoveBookmarkEvent(
                                          bookmark.surahId,
                                          bookmark.verseNumber,
                                        ),
                                      );
                                    },
                                    tooltip: 'lbl_delete'.tr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            );
          } else if (state is BookmarkError) {
            return Center(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${'lbl_error'.tr}: ${state.message.tr}',
                  style: TextStyle(
                    color: isDark ? Colors.redAccent : Colors.red,
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import '../../core/app_export.dart';
import 'bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/rtl_utils.dart';
import '../../core/utils/surah_name_formatter.dart';

class RecitationErrorScreen extends StatelessWidget {
  const RecitationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(rtlBackArrow(context)),
          onPressed: () => NavigatorService.goBack(),
        ),
        centerTitle: true,
        title: Text('lbl_practice_list'.tr, style: AppTextStyles.headingMedium),
      ),
      body: BlocConsumer<RecitationErrorBloc, RecitationErrorState>(
        listener: (context, state) {
          if (state is RecitationErrorLoaded) {
            // Optional: Show snackbar on error removal if needed, or handle in UI
          }
        },
        builder: (context, state) {
          if (state is RecitationErrorLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RecitationErrorLoaded) {
            if (state.errors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'msg_no_practice_items'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: state.errors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final error = state.errors[index];
                return Dismissible(
                  key: Key('${error.surahId}_${error.verseId}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  onDismissed: (direction) {
                    SnackBarHelper.show(
                      context,
                      message: 'msg_removed_practice'.tr,
                    );
                    context.read<RecitationErrorBloc>().add(
                      RemoveRecitationErrorEvent(error.surahId, error.verseId),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                          .colorScheme
                          .outlineVariant,
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
                              'surah': QuranIndex.quranSurahs.firstWhere(
                                (e) => e.id == error.surahId,
                                orElse: () => QuranIndex.quranSurahs[0],
                              ),
                              'verseIndex': error.verseId - 1,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      QuranIndex.quranSurahs
                                          .firstWhere(
                                            (e) => e.id == error.surahId,
                                            orElse: () =>
                                                QuranIndex.quranSurahs[0],
                                          )
                                          .localizedName(context),
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
                                      '${'lbl_verse_num'.tr} ${error.verseId.toLocalizedNumber(context)}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
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
                  ),
                );
              },
            );
          } else if (state is RecitationErrorError) {
            return Center(
              child: Text('${"lbl_error".tr}: ${state.message.tr}'),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import '../../core/utils/number_converter.dart';
import '../../core/utils/surah_name_formatter.dart';

class RecitationErrorScreen extends StatelessWidget {
  const RecitationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigatorService.goBack(),
        ),
        centerTitle: true,
        title: Text(
          'lbl_practice_list'.tr,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'msg_no_practice_items'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                              'surah': QuranIndex.quranSurahs.firstWhere(
                                (e) => e.id == error.surahId,
                                orElse: () => QuranIndex.quranSurahs[0],
                              ),
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
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
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
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2D2D2D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${'lbl_verse_num'.tr} ${error.verseId.toLocalizedNumber(context)}',
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

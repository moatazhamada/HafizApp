import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/quran_index/quran_surah.dart';
import '../../../core/utils/number_converter.dart';
import '../../../core/utils/rtl_utils.dart';

class ContinueReadingCard extends StatelessWidget {
  final Surah? surah;
  final int? lastVerseIndex;
  final VoidCallback? onContinue;

  const ContinueReadingCard({
    super.key,
    this.surah,
    this.lastVerseIndex,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (surah == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Semantics(
      container: true,
      label:
          '${'lbl_last_read'.tr}: ${surah!.nameEnglish}${lastVerseIndex != null ? ', ${'lbl_ayah'.tr} ${lastVerseIndex! + 1}' : ''}',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                AppColors.of(context).primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                right: -30,
                bottom: -30,
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 150,
                    color: AppColors.of(context).onPrimary.withValues(alpha: 0.1),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.menu_book,
                            color: AppColors.of(context).onPrimary.withValues(
                              alpha: 0.7,
                            ),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'lbl_last_read'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.of(context).onPrimary.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isArabic)
                                Text(
                                  surah!.nameEnglish,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.of(context).onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                surah!.nameArabic,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 22,
                                  color: AppColors.of(context).onPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lastVerseIndex != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.of(context).onPrimary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.of(context).onPrimary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              '${"lbl_ayah".tr} ${(lastVerseIndex! + 1).toLocalizedNumber(context)}',
                              style: TextStyle(
                                color: AppColors.of(context).onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Semantics(
                      button: true,
                      label: 'lbl_continue'.tr,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.of(context).onPrimary,
                            foregroundColor: theme.colorScheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'lbl_continue'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(rtlForwardArrowRounded(context), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

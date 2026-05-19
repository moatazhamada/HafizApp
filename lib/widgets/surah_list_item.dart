import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/core/quran_index/quran_verse_utils.dart';
import 'package:hafiz_app/localization/app_localization.dart';

class SurahListItem extends StatelessWidget {
  final int surahId;
  final String nameEnglish;
  final String nameArabic;

  const SurahListItem({
    super.key,
    required this.surahId,
    required this.nameEnglish,
    required this.nameArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appColors = AppColors.of(context);
    
    final ayahCount = getSurahVerseCount(surahId);
    final revelationType = getRevelationType(surahId);
    
    final revelationText = revelationType == 'Meccan' ? 'lbl_meccan'.tr : 'lbl_medinan'.tr;
    final ayahsText = 'lbl_ayahs'.tr;
    final ayahLocalizedCount = ayahCount.toLocalizedNumber(context);

    return Semantics(
      button: true,
      label: '$nameEnglish, $nameArabic',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? colorScheme.outline.withValues(alpha: 0.2) : appColors.mushafPageBorder,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: Localizations.localeOf(context).languageCode != 'ar'
                ? [
                    // Number Badge (Left)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? appColors.primaryDark : appColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        surahId.toLocalizedNumber(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Middle Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameEnglish,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$ayahLocalizedCount $ayahsText • $revelationText',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Arabic Name (Right)
                    Text(
                      nameArabic,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: 'NotoNaskhArabic',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ]
                : [
                    // Text (Right)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameArabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'NotoNaskhArabic',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$ayahLocalizedCount $ayahsText • $revelationText',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Number Badge (Left)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? appColors.primaryDark : appColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        surahId.toLocalizedNumber(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

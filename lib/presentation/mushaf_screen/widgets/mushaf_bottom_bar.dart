import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';

class MushafBottomBar extends StatelessWidget {
  final int currentPage;
  final MushafType mushafType;
  final AppColors colors;
  final VoidCallback onJumpPressed;

  const MushafBottomBar({
    super.key,
    required this.currentPage,
    required this.mushafType,
    required this.colors,
    required this.onJumpPressed,
  });

  int _toMadaniPage(int page) {
    if (mushafType.totalPages == MushafPageIndex.totalPages) {
      return page;
    }
    return (page / mushafType.totalPages * MushafPageIndex.totalPages)
        .round()
        .clamp(1, MushafPageIndex.totalPages);
  }

  @override
  Widget build(BuildContext context) {
    final madaniPage = _toMadaniPage(currentPage);
    final pageData = MushafPageIndex.getPageData(madaniPage);
    final surahId =
        pageData?.surahId ?? MushafPageIndex.getSurahForPage(madaniPage);
    final surah = surahId >= 1 && surahId <= 114
        ? QuranIndex.quranSurahs[surahId - 1]
        : null;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final juz = mushafType.getJuzForPage(currentPage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colors.mushafPageBg,
            colors.mushafPageBg.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (surah != null)
                Text(
                  isArabic ? surah.nameArabic : surah.nameEnglish,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${'lbl_juz'.tr} ${juz.toLocalizedNumber(context)}',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'lbl_semantics_page_indicator'
                        .tr
                        .replaceAll('{current}', '$currentPage')
                        .replaceAll('{total}', '${mushafType.totalPages}'),
                    child: GestureDetector(
                      onTap: onJumpPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mushafPageBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentPage.toLocalizedNumber(context)} / ${mushafType.totalPages.toLocalizedNumber(context)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

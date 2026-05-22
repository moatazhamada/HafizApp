import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../core/quran_index/mushaf_page_index.dart';
import '../../../core/quran_index/quran_surah.dart';

class JuzProgressIndicator extends StatelessWidget {
  final Surah? surah;

  const JuzProgressIndicator({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    if (surah == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final page = MushafPageIndex.getPageForSurah(surah!.id);
    final juz = MushafPageIndex.getJuzForPage(page);
    final colors = AppColors.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAr ? 'الجزء $juz' : 'Juz $juz',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: juz / 30.0,
                  minHeight: 4,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

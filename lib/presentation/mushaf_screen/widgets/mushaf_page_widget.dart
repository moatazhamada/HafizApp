import 'package:flutter/material.dart';
import 'package:hafiz_app/core/mushaf/mushaf_page_verse_map.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';
import 'package:hafiz_app/presentation/mushaf_screen/widgets/mushaf_glyph_painter.dart';

class MushafPageWidget extends StatelessWidget {
  final int pageNumber;
  final MushafPageData? pageData;
  final bool isLoading;
  final bool isDark;
  final String errorMessage;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.pageData,
    this.isLoading = false,
    this.isDark = false,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (isLoading) {
      return Container(
        color: colors.mushafPageBg,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (pageData != null && pageData!.hasGlyphData) {
      return Container(
        color: colors.mushafPageBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildSurahHeader(context),
                const SizedBox(height: 8),
                Expanded(
                  child: MushafGlyphPainter(
                    pageData: pageData!,
                    isDark: isDark,
                  ),
                ),
                _buildPageNumber(context),
              ],
            ),
          ),
        ),
      );
    }

    return _buildFallbackPage(context, colors);
  }

  Widget _buildSurahHeader(BuildContext context) {
    final surahId = MushafPageIndex.getSurahForPage(pageNumber);
    if (surahId < 1 || surahId > 114) return const SizedBox.shrink();

    final surahStartPage = MushafPageIndex.getPageForSurah(surahId);
    if (surahStartPage != pageNumber) return const SizedBox.shrink();

    final surah = QuranIndex.quranSurahs[surahId - 1];

    final colors = AppColors.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.mushafPageBorder),
              bottom: BorderSide(color: colors.mushafPageBorder),
            ),
          ),
          child: Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.mushafSurahHeaderColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (surah.id != 1 && surah.id != 9 && surahStartPage == pageNumber)
          Text(
            '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
            '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
            '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
      ],
    );
  }

  Widget _buildPageNumber(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        _toArabicNumeral(pageNumber),
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }

  Widget _buildFallbackPage(BuildContext context, AppColors colors) {
    final ranges = MushafPageVerseMap.getVersesForPage(pageNumber);
    if (ranges.isEmpty) {
      return Container(
        color: colors.mushafPageBg,
        child: Center(
          child: Text(
            errorMessage.isNotEmpty ? errorMessage : 'Page $pageNumber',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      color: colors.mushafPageBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildSurahHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FallbackTextPainter(
                    ranges: ranges,
                    isDark: isDark,
                    textColor: colors.mushafTextPrimary,
                  ),
                ),
              ),
            ),
            _buildPageNumber(context),
          ],
        ),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const d = [
      '\u0660', '\u0661', '\u0662', '\u0663', '\u0664',
      '\u0665', '\u0666', '\u0667', '\u0668', '\u0669',
    ];
    return number.toString().split('').map((c) {
      final n = int.tryParse(c);
      return n != null ? d[n] : c;
    }).join();
  }
}

class _FallbackTextPainter extends CustomPainter {
  final List<MushafPageRange> ranges;
  final bool isDark;
  final Color textColor;

  _FallbackTextPainter({
    required this.ranges,
    required this.isDark,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      fontSize: 18,
      color: textColor,
      fontFamily: 'NotoNaskhArabic',
    );

    final columnWidth = (size.width - 24) / 2;
    double y = 0;
    const double lineHeight = 36;

    for (final range in ranges) {
      final surah = QuranIndex.quranSurahs[range.surahId - 1];
      final label = '${surah.nameArabic} '
          '${range.startVerse} - ${range.endVerse}';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(
            fontSize: 14,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: columnWidth);

      tp.paint(canvas, Offset(8, y));
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(_FallbackTextPainter oldDelegate) =>
      ranges != oldDelegate.ranges || isDark != oldDelegate.isDark;
}

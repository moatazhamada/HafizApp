import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/mushaf/mushaf_rendering_config.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/presentation/mushaf_screen/bloc/mushaf_state.dart';

class MushafPageWidget extends StatelessWidget {
  final int pageNumber;
  final List<AyahEntry> entries;
  final bool isLoading;
  final bool isDark;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.entries = const [],
    this.isLoading = false,
    this.isDark = false,
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

    if (entries.isEmpty) {
      return Container(color: colors.mushafPageBg);
    }

    return Container(
      color: colors.mushafPageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: entries.map((entry) {
                          if (entry.isSurahHeader) {
                            return _buildSurahHeader(colors, entry);
                          }
                          return _buildVerseImage(entry);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildPageNumber(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurahHeader(AppColors colors, AyahEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            entry.surahNameArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.mushafSurahHeaderColor,
            ),
          ),
          if (entry.showBismillah)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
                    '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
                    '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerseImage(AyahEntry entry) {
    final url = MushafRenderingConfig.ayahImageUrl(
      entry.surahId,
      entry.verseNumber,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.fitWidth,
        placeholder: (ctx, url) => const SizedBox(
          height: 28,
          child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
        ),
        errorWidget: (ctx, url, err) => _buildVerseFallback(entry),
      ),
    );
  }

  Widget _buildVerseFallback(AyahEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '\u06DD${_toArabicNumeral(entry.verseNumber)}',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }

  Widget _buildPageNumber() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            _toArabicNumeral(pageNumber),
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
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

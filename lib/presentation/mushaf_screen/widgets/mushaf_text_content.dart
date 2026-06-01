import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'verse_text.dart';

class MushafTextContent extends StatelessWidget {
  final AppColors colors;
  final List<VerseText> verses;

  const MushafTextContent({
    super.key,
    required this.colors,
    required this.verses,
  });

  String _toArabicNumeral(int number) {
    const d = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
    ];
    return number.toString().split('').map((c) {
      final n = int.tryParse(c);
      return n != null ? d[n] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = PrefUtils().getQuranFontSize();
    final textColor = colors.mushafTextPrimary;
    final verseNumColor = colors.textSecondary;

    final List<InlineSpan> spans = [];
    final arabicVerseNumStyle = TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: fontSize - 4,
      color: verseNumColor,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < verses.length; i++) {
      final v = verses[i];
      if (v.text.isEmpty) continue;

      if (v.verseNumber == 1) {
        if (i > 0) spans.add(const TextSpan(text: '\n'));
        spans.add(
          TextSpan(
            text: '${v.surahNameArabic}\n',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colors.mushafSurahHeaderColor,
            ),
          ),
        );
        if (v.showBismillah) {
          spans.add(
            TextSpan(
              text:
                  '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
                  '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
                  '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650\n',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: PrefUtils().getQuranFontSize() - 8,
                color: colors.textSecondary,
              ),
            ),
          );
        }
      }

      spans.add(
        TextSpan(
          text: '${v.text} ',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: fontSize,
            height: 2.0,
            color: textColor,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: ' \u06DD${_toArabicNumeral(v.verseNumber)} ',
          style: arabicVerseNumStyle,
        ),
      );
    }

    return SingleChildScrollView(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }
}

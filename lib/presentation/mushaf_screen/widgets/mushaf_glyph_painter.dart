import 'package:flutter/material.dart';
import 'package:hafiz_app/data/datasource/mushaf/qf_mushaf_page_data_source.dart';

class MushafGlyphPainter extends StatelessWidget {
  final MushafPageData pageData;
  final bool isDark;
  final double fontSize;

  const MushafGlyphPainter({
    super.key,
    required this.pageData,
    required this.isDark,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (pageData.lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = isDark ? const Color(0xFFE8D5B7) : const Color(0xFF1A1A1A);
    final totalLines = pageData.lines.length;
    final midLine = (totalLines / 2).ceil();

    final rightLines = pageData.lines.where((l) => l.lineNumber < midLine).toList();
    final leftLines = pageData.lines.where((l) => l.lineNumber >= midLine).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildColumn(leftLines, color)),
        Container(width: 2, color: isDark ? Colors.white12 : Colors.black12),
        Expanded(child: _buildColumn(rightLines, color)),
      ],
    );
  }

  Widget _buildColumn(List<GlyphLine> lines, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line.combinedCodeV2,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }
}

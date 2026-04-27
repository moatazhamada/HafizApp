import 'package:dio/dio.dart';
import 'package:hafiz_app/core/mushaf/mushaf_rendering_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Exact verse reference on a page — surah:verse parsed from API verse_key.
class PageVerse {
  final String verseKey;
  final int surahId;
  final int verseNumber;
  final int pageNumber;

  const PageVerse({
    required this.verseKey,
    required this.surahId,
    required this.verseNumber,
    required this.pageNumber,
  });

  factory PageVerse.fromJson(Map<String, dynamic> json) {
    final key = (json['verse_key'] ?? '') as String;
    final parts = key.split(':');
    return PageVerse(
      verseKey: key,
      surahId: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0,
      verseNumber: (json['verse_number'] ?? 0) as int,
      pageNumber: (json['page_number'] ?? 0) as int,
    );
  }
}

/// A word with glyph codes for font-based rendering.
class GlyphWord {
  final int position;
  final String codeV1;
  final String codeV2;
  final int lineV2;

  const GlyphWord({
    required this.position,
    required this.codeV1,
    required this.codeV2,
    required this.lineV2,
  });

  factory GlyphWord.fromJson(Map<String, dynamic> json) {
    return GlyphWord(
      position: (json['position'] ?? 0) as int,
      codeV1: (json['code_v1'] ?? '').toString(),
      codeV2: (json['code_v2'] ?? '').toString(),
      lineV2: (json['line_v2'] ?? 0) as int,
    );
  }
}

/// Complete page data from the QF Content API.
class MushafPageData {
  final int pageNumber;
  final List<PageVerse> verses;
  final Map<String, List<GlyphWord>> wordsByVerse; // verseKey → words

  const MushafPageData({
    required this.pageNumber,
    required this.verses,
    required this.wordsByVerse,
  });

  /// Glyph lines: groups code_v2 glyphs by their line number.
  Map<int, List<String>> get glyphLines {
    final Map<int, List<String>> result = {};
    for (final words in wordsByVerse.values) {
      for (final w in words) {
        result.putIfAbsent(w.lineV2, () => []);
        result[w.lineV2]!.add(w.codeV2);
      }
    }
    return result;
  }

  bool get isEmpty => verses.isEmpty;
  bool get hasGlyphData => wordsByVerse.isNotEmpty;
}

abstract class QfMushafPageDataSource {
  Future<MushafPageData?> fetchPage(int pageNumber);
}

class QfMushafPageDataSourceImpl implements QfMushafPageDataSource {
  final Dio _dio;

  QfMushafPageDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<MushafPageData?> fetchPage(int pageNumber) async {
    try {
      final url = MushafRenderingConfig.glyphPageUrl(pageNumber);
      final response = await _dio.get(url);

      if (response.statusCode != 200) return null;

      final data = response.data;
      final versesRaw = data['verses'] as List<dynamic>? ?? [];
      if (versesRaw.isEmpty) return null;

      final verses = <PageVerse>[];
      final wordsByVerse = <String, List<GlyphWord>>{};

      for (final v in versesRaw) {
        if (v is! Map<String, dynamic>) continue;
        final pv = PageVerse.fromJson(v);
        verses.add(pv);

        final wordsRaw = v['words'] as List<dynamic>? ?? [];
        if (wordsRaw.isNotEmpty) {
          wordsByVerse[pv.verseKey] = wordsRaw
              .whereType<Map<String, dynamic>>()
              .map((w) => GlyphWord.fromJson(w))
              .toList();
        }
      }

      return MushafPageData(
        pageNumber: pageNumber,
        verses: verses,
        wordsByVerse: wordsByVerse,
      );
    } catch (e) {
      Logger.error('Failed to fetch mushaf page $pageNumber: $e',
          feature: 'Mushaf');
      return null;
    }
  }
}

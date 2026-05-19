import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

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

class GlyphWord {
  final int position;
  final String codeV2;
  final int lineV2;

  const GlyphWord({
    required this.position,
    required this.codeV2,
    required this.lineV2,
  });

  factory GlyphWord.fromJson(Map<String, dynamic> json) {
    return GlyphWord(
      position: (json['position'] ?? 0) as int,
      codeV2: (json['code_v2'] ?? '').toString(),
      lineV2: (json['line_v2'] ?? 0) as int,
    );
  }
}

class GlyphLine {
  final int lineNumber;
  final List<GlyphWord> words;

  GlyphLine({required this.lineNumber, List<GlyphWord>? words})
      : words = words ?? [];

  String get combinedCodeV2 => words.map((w) => w.codeV2).join();

  String get combinedText => combinedCodeV2;
}

class MushafPageData {
  final int pageNumber;
  final List<PageVerse> verses;
  final Map<String, List<GlyphWord>> wordsByVerse;
  final List<GlyphLine> lines;

  const MushafPageData({
    required this.pageNumber,
    required this.verses,
    required this.wordsByVerse,
    required this.lines,
  });

  bool get isEmpty => verses.isEmpty;
  bool get hasGlyphData => wordsByVerse.isNotEmpty;
}

abstract class QfMushafPageDataSource {
  Future<MushafPageData?> fetchPage(int pageNumber);
}

class CachedQfMushafPageDataSource implements QfMushafPageDataSource {
  final QfMushafPageDataSource _inner;
  final Map<int, MushafPageData> _cache = {};
  final List<int> _cacheOrder = [];
  static const int _maxCacheSize = 20;

  CachedQfMushafPageDataSource({required QfMushafPageDataSource inner})
      : _inner = inner;

  @override
  Future<MushafPageData?> fetchPage(int pageNumber) async {
    if (_cache.containsKey(pageNumber)) {
      _cacheOrder.remove(pageNumber);
      _cacheOrder.add(pageNumber);
      return _cache[pageNumber];
    }

    final data = await _inner.fetchPage(pageNumber);
    if (data != null) {
      if (_cache.length >= _maxCacheSize) {
        final oldest = _cacheOrder.removeAt(0);
        _cache.remove(oldest);
      }
      _cache[pageNumber] = data;
      _cacheOrder.add(pageNumber);
    }
    return data;
  }

  Future<void> prefetchPages(List<int> pageNumbers) async {
    final pagesToFetch = pageNumbers.where((p) => !_cache.containsKey(p)).toList();
    final results = await Future.wait(
      pagesToFetch.map((page) => _inner.fetchPage(page)),
    );
    for (int i = 0; i < pagesToFetch.length; i++) {
      final data = results[i];
      if (data != null) {
        if (_cache.length >= _maxCacheSize) {
          final oldest = _cacheOrder.removeAt(0);
          _cache.remove(oldest);
        }
        _cache[pagesToFetch[i]] = data;
        _cacheOrder.add(pagesToFetch[i]);
      }
    }
  }
}

class QfMushafPageDataSourceImpl implements QfMushafPageDataSource {
  final Dio _dio;

  QfMushafPageDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<MushafPageData?> fetchPage(int pageNumber) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contentApiBase}/verses/by_page/$pageNumber',
        queryParameters: {
          'fields': 'code_v1,code_v2,v2_page,page_number',
          'words': 'true',
          'word_fields': 'code_v1,code_v2,position,v2_page,line_v2,page_number',
          'per_page': 300,
        },
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      final versesRaw = data['verses'] as List<dynamic>? ?? [];
      if (versesRaw.isEmpty) return null;

      final verses = <PageVerse>[];
      final wordsByVerse = <String, List<GlyphWord>>{};
      final lineMap = <int, GlyphLine>{};

      for (final v in versesRaw) {
        if (v is! Map<String, dynamic>) continue;
        final pv = PageVerse.fromJson(v);
        verses.add(pv);

        final wordsRaw = v['words'] as List<dynamic>? ?? [];
        if (wordsRaw.isNotEmpty) {
          final glyphWords = wordsRaw
              .whereType<Map<String, dynamic>>()
              .map((w) => GlyphWord.fromJson(w))
              .toList();
          wordsByVerse[pv.verseKey] = glyphWords;

          for (final gw in glyphWords) {
            final line = lineMap.putIfAbsent(
              gw.lineV2,
              () => GlyphLine(lineNumber: gw.lineV2, words: []),
            );
            line.words.add(gw);
          }
        }
      }

      final lineNumbers = lineMap.keys.toList()..sort();
      final lines = lineNumbers.map((ln) => lineMap[ln]!).toList();

      return MushafPageData(
        pageNumber: pageNumber,
        verses: verses,
        wordsByVerse: wordsByVerse,
        lines: lines,
      );
    } catch (e) {
      Logger.error('Failed to fetch mushaf page $pageNumber: $e',
          feature: 'Mushaf');
      return null;
    }
  }
}

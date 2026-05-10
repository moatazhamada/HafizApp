import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../model/surah_response.dart';

abstract class SurahLocalDataSource {
  Future<ChapterResponse> getSurah(String surahId);
  Future<List<VerseModel>> searchVerses(String query);
}

class SurahLocalDataSourceImpl implements SurahLocalDataSource {
  final String basePath;

  SurahLocalDataSourceImpl({this.basePath = 'assets/quran/uthmani'});

  /// Static in-memory cache of all decoded surah data.
  /// Key: basePath. All 114 surahs decoded (~2-3MB), loaded once.
  /// Call [invalidateCache] when locale/data changes to force a reload.
  static Map<String, List<Map<String, dynamic>>>? _surahCache;

  /// Per-surah result cache: key is '$basePath:$surahId'.
  static final Map<String, ChapterResponse> _responseCache = {};

  /// LRU query-result cache (max 50 entries).
  /// Key: "basePath$normalizedQuery". Evicts oldest entry when full.
  static final Map<String, List<Map<String, dynamic>>> _queryCache = {};
  static const int _maxQueryCacheSize = 50;

  /// Clear both caches. Call on locale change or when data must be refreshed.
  static void invalidateCache() {
    _surahCache?.clear();
    _queryCache.clear();
  }

  @override
  Future<ChapterResponse> getSurah(String surahId) async {
    final surahIndex = int.tryParse(surahId) ?? 0;
    if (surahIndex < 1 || surahIndex > 114) {
      return ChapterResponse(chapters: []);
    }

    final cacheKey = '$basePath:$surahId';

    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }

    if (_surahCache != null && _surahCache!.containsKey(basePath)) {
      final all = _surahCache![basePath]!;
      if (surahIndex - 1 < all.length) {
        final response = ChapterResponse.fromJson(all[surahIndex - 1]);
        _responseCache[cacheKey] = response;
        return response;
      }
    }

    final path = '$basePath/surah_$surahId.json';
    final jsonStr = await rootBundle.loadString(path);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final response = ChapterResponse.fromJson(data);
    _responseCache[cacheKey] = response;
    return response;
  }

  Future<List<ChapterResponse>> preloadAllSurahs() async {
    return Future.wait(
      List.generate(114, (i) => getSurah((i + 1).toString())),
    );
  }

  @override
  Future<List<VerseModel>> searchVerses(String query) async {
    try {
      final normalizedQuery = _removeTashkeel(query);
      final queryCacheKey = '$basePath\$$normalizedQuery';

      // 1. Fast path: return cached query result
      if (_queryCache.containsKey(queryCacheKey)) {
        return _queryCache[queryCacheKey]!.map(VerseModel.fromJson).toList();
      }

      // 2. Ensure surah data is loaded and cached
      _surahCache ??= {};
      if (!_surahCache!.containsKey(basePath)) {
        final token = RootIsolateToken.instance;
        if (token == null) {
          debugPrint(
            'RootIsolateToken is null, cannot spawn isolate with channels',
          );
          return [];
        }

        final results = await compute(_loadAllSurahsWorker, <String, Object?>{
          'token': token,
          'basePath': basePath,
        });
        _surahCache![basePath] = results;
      }

      // 3. Search cached data in an isolate
      final rawMatches = await compute(_searchCachedWorker, <String, Object?>{
        'surahs': _surahCache![basePath]!,
        'query': query,
        'normalizedQuery': normalizedQuery,
      });

      // 4. Cache query results with LRU eviction
      _queryCache[queryCacheKey] = rawMatches;
      if (_queryCache.length > _maxQueryCacheSize) {
        _queryCache.remove(_queryCache.keys.first);
      }

      return rawMatches.map(VerseModel.fromJson).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }
}

// ---------------------------------------------------------------------------
// Static regex for performance (compile once)
// ---------------------------------------------------------------------------
final _tashkeelRegex = RegExp(
  r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
);

String _removeTashkeel(String text) => text.replaceAll(_tashkeelRegex, '');

// ---------------------------------------------------------------------------
// Isolate workers
// ---------------------------------------------------------------------------

/// Loads all 114 surah files from assets and returns decoded maps.
Future<List<Map<String, dynamic>>> _loadAllSurahsWorker(
  Map<String, Object?> args,
) async {
  final token = args['token'] as RootIsolateToken;
  final basePath = args['basePath'] as String;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final List<Map<String, dynamic>> surahs = [];
  for (int i = 1; i <= 114; i++) {
    try {
      final jsonStr = await rootBundle.loadString('$basePath/surah_$i.json');
      surahs.add(json.decode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error loading surah $i: $e');
    }
  }
  return surahs;
}

/// Searches pre-loaded surah data for verses matching [normalizedQuery].
Future<List<Map<String, dynamic>>> _searchCachedWorker(
  Map<String, Object?> args,
) async {
  final surahs = args['surahs'] as List<Map<String, dynamic>>;
  final normalizedQuery = args['normalizedQuery'] as String;

  final List<Map<String, dynamic>> allMatches = [];

  for (final surahData in surahs) {
    try {
      final response = ChapterResponse.fromJson(surahData);

      for (final verse in response.chapters) {
        String textToCheck = verse.arabicText;

        // Exclude Bismillah from search for all Surahs except Al-Fatiha (1)
        if (verse.chapterNumber != 1 && verse.verseNumber == 1) {
          const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
          if (textToCheck.startsWith(bismillahPrefix)) {
            textToCheck = textToCheck.substring(bismillahPrefix.length).trim();
          } else {
            const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
            if (textToCheck.startsWith(bismillahSimple)) {
              textToCheck = textToCheck
                  .substring(bismillahSimple.length)
                  .trim();
            }
          }
        }

        final normalizedVerse = _removeTashkeel(textToCheck);
        if (normalizedVerse.contains(normalizedQuery)) {
          allMatches.add({
            'chapter': verse.chapterNumber,
            'verse': verse.verseNumber,
            'text': verse.arabicText,
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching surah: $e');
    }
  }
  return allMatches;
}


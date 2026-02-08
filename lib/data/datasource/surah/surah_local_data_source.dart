import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../model/surah_response.dart';

abstract class SurahLocalDataSource {
  Future<ChapterResponse> getSurah(String surahId);
  Future<List<VerseModel>> searchVerses(String query, {int maxResults});
}

class SurahLocalDataSourceImpl implements SurahLocalDataSource {
  final String basePath;

  SurahLocalDataSourceImpl({this.basePath = 'assets/quran/uthmani'});

  @override
  Future<ChapterResponse> getSurah(String surahId) async {
    final path = '$basePath/surah_$surahId.json';
    final jsonStr = await rootBundle.loadString(path);
    final data = await compute(_decodeJsonToMap, jsonStr);
    return ChapterResponse.fromJson(data);
  }

  @override
  Future<List<VerseModel>> searchVerses(
    String query, {
    int maxResults = 50,
  }) async {
    try {
      final token = RootIsolateToken.instance;
      if (token == null) {
        debugPrint(
          'RootIsolateToken is null, cannot spawn isolate with channels',
        );
        return [];
      }

      final rawMatches = await compute(_searchWorker, <String, Object?>{
        'token': token,
        'basePath': basePath,
        'query': query,
        'maxResults': maxResults,
      });

      return rawMatches.map(VerseModel.fromJson).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }
}

// Static regex for performance (compile once)
final _tashkeelRegex = RegExp(
  r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
);

String _removeTashkeel(String text) => text.replaceAll(_tashkeelRegex, '');

Future<List<Map<String, dynamic>>> _searchWorker(
  Map<String, Object?> args,
) async {
  try {
    // Validate all inputs
    final token = args['token'];
    if (token is! RootIsolateToken) {
      debugPrint('Invalid token type in search worker');
      return [];
    }

    final basePath = args['basePath'];
    if (basePath is! String || basePath.isEmpty) {
      debugPrint('Invalid basePath in search worker');
      return [];
    }

    final query = args['query'];
    if (query is! String || query.isEmpty) {
      debugPrint('Invalid query in search worker');
      return [];
    }

    final maxResults = args['maxResults'];
    if (maxResults is! int || maxResults <= 0) {
      debugPrint('Invalid maxResults in search worker');
      return [];
    }

    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final List<Map<String, dynamic>> allMatches = [];
    final normalizedQuery = _removeTashkeel(query);

    for (int i = 1; i <= 114; i++) {
      // Early exit if we've reached max results
      if (allMatches.length >= maxResults) break;
      try {
        final jsonStr = await rootBundle.loadString('$basePath/surah_$i.json');

        // Optimization: Pre-check on normalized raw JSON to skip parsing entirely
        final normalizedJson = _removeTashkeel(jsonStr);
        if (!normalizedJson.contains(normalizedQuery)) continue;

        // Parse only if we have a potential match
        final Map<String, dynamic> data = json.decode(jsonStr);
        final response = ChapterResponse.fromJson(data);

        for (final verse in response.chapters) {
          String textToCheck = verse.text;

          // Exclude Bismillah from search for all Surahs except Al-Fatiha (1)
          if (verse.chapterId != 1 && verse.verseNumber == 1) {
            const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
            if (textToCheck.startsWith(bismillahPrefix)) {
              textToCheck = textToCheck
                  .substring(bismillahPrefix.length)
                  .trim();
            } else {
              // Fallback for simple encoding
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
              'chapter': verse.chapterId,
              'verse': verse.verseNumber,
              'text': verse.text,
            });

            // Check if we've reached max results
            if (allMatches.length >= maxResults) break;
          }
        }
      } catch (e) {
        debugPrint('Error searching surah $i: $e');
      }
    }
    return allMatches;
  } catch (e, stackTrace) {
    debugPrint('Fatal error in search worker: $e\n$stackTrace');
    return [];
  }
}

Map<String, dynamic> _decodeJsonToMap(String jsonStr) {
  return json.decode(jsonStr) as Map<String, dynamic>;
}

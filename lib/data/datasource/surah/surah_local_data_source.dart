import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../model/surah_response.dart';

abstract class SurahLocalDataSource {
  Future<ChapterResponse> getSurah(String surahId);
  Future<List<VerseModel>> searchVerses(String query);
}

class SurahLocalDataSourceImpl implements SurahLocalDataSource {
  final String basePath;

  SurahLocalDataSourceImpl({this.basePath = 'assets/quran/uthmani'});

  @override
  Future<ChapterResponse> getSurah(String surahId) async {
    final path = '$basePath/surah_$surahId.json';
    final jsonStr = await rootBundle.loadString(path);
    return compute(_parseSurahJson, jsonStr);
  }

  @override
  Future<List<VerseModel>> searchVerses(String query) async {
    try {
      // 1. Load all assets in parallel (IO bound, fast on main)
      final loadFutures = List.generate(114, (index) {
        final surahId = index + 1;
        return rootBundle.loadString('$basePath/surah_$surahId.json');
      });
      final allJsonStrings = await Future.wait(loadFutures);

      // 2. Offload parsing and searching to a SINGLE isolate
      return compute(_searchWorker, _SearchRequest(allJsonStrings, query));
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }
}

class _SearchRequest {
  final List<String> jsonStrings;
  final String query;
  _SearchRequest(this.jsonStrings, this.query);
}

// Static regex for performance (compile once)
final _tashkeelRegex = RegExp(
  r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
);

String _removeTashkeel(String text) => text.replaceAll(_tashkeelRegex, '');

List<VerseModel> _searchWorker(_SearchRequest request) {
  final List<VerseModel> allMatches = [];
  final normalizedQuery = _removeTashkeel(request.query);

  for (final jsonStr in request.jsonStrings) {
    // Optimization: Pre-check on normalized raw JSON to skip parsing entirely
    // This is a heuristic—if the normalized query is NOT in the normalized JSON, we skip.
    final normalizedJson = _removeTashkeel(jsonStr);
    if (!normalizedJson.contains(normalizedQuery)) continue;

    // Parse only if we have a potential match
    final Map<String, dynamic> data = json.decode(jsonStr);
    final response = ChapterResponse.fromJson(data);

    for (final verse in response.chapters) {
      String textToCheck = verse.text;

      // Exclude Bismillah from search for all Surahs except Al-Fatiha (1)
      if (verse.chapterId != 1 && verse.verseNumber == 1) {
        const bismillahPrefix = "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ";
        if (textToCheck.startsWith(bismillahPrefix)) {
          textToCheck = textToCheck.substring(bismillahPrefix.length).trim();
        } else {
          // Fallback for simple encoding
          const bismillahSimple = "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ";
          if (textToCheck.startsWith(bismillahSimple)) {
            textToCheck = textToCheck.substring(bismillahSimple.length).trim();
          }
        }
      }

      final normalizedVerse = _removeTashkeel(textToCheck);
      if (normalizedVerse.contains(normalizedQuery)) {
        allMatches.add(verse);
        // User requested NO early exit.
        // if (allMatches.length >= 50) return allMatches;
      }
    }
  }
  return allMatches;
}

ChapterResponse _parseSurahJson(String jsonStr) {
  final Map<String, dynamic> data = json.decode(jsonStr);
  return ChapterResponse.fromJson(data);
}

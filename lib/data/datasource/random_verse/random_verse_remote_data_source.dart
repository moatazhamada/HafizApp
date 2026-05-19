import 'dart:math';

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/surah/surah_local_data_source.dart';
import 'package:hafiz_app/data/model/surah_response.dart';

class RandomVerseData {
  final int verseId;
  final int chapterId;
  final int verseNumber;
  final String verseKey;
  final String arabicText;
  final String englishText;

  const RandomVerseData({
    required this.verseId,
    required this.chapterId,
    required this.verseNumber,
    required this.verseKey,
    required this.arabicText,
    required this.englishText,
  });
}

class RandomVerseRemoteDataSource {
  final Dio _dio;
  final SurahLocalDataSource _localDataSource;

  RandomVerseRemoteDataSource({
    required Dio dio,
    required SurahLocalDataSource localDataSource,
  })  : _dio = dio,
        _localDataSource = localDataSource;

  Future<RandomVerseData?> fetchRandomVerse() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contentApiBase}/verses/random',
        queryParameters: {
          'translations': '${ApiConfig.translationId}',
          'words': 'true',
          'fields': 'text_uthmani',
        },
      );

      final verse = response.data['verse'] as Map<String, dynamic>?;
      if (verse == null) return null;

      final verseKey = verse['verse_key'] as String? ?? '';
      final chapterId =
          verse['chapter_id'] as int? ??
          int.tryParse(verseKey.split(':').first) ??
          1;

      final arabicText = verse['text_uthmani'] as String? ?? '';

      // Translation text comes via the verse.translations array.
      final translations = (verse['translations'] as List?)
          ?.cast<Map<String, dynamic>>();
      final englishText = (translations != null && translations.isNotEmpty)
          ? _cleanText(translations[0]['text'] as String? ?? '')
          : '';

      return RandomVerseData(
        verseId: verse['id'] as int? ?? 0,
        chapterId: chapterId,
        verseNumber: verse['verse_number'] as int? ?? 1,
        verseKey: verseKey,
        arabicText: arabicText,
        englishText: englishText,
      );
    } catch (e) {
      Logger.warning(
        'Failed to fetch random verse: $e',
        feature: 'RandomVerse',
      );
      return null;
    }
  }

  /// Fetches a random verse from local assets when the API is unavailable.
  /// [daily] uses the current date as a seed so the same verse is shown
  /// throughout the day (useful for "Verse of the Day" fallback).
  Future<RandomVerseData?> fetchLocalRandomVerse({bool daily = false}) async {
    try {
      final now = DateTime.now();
      final random = daily
          ? Random(now.year * 10000 + now.month * 100 + now.day)
          : Random();

      // Pick a random surah (1-114)
      final surahId = random.nextInt(114) + 1;
      final verseCount = MushafPageIndex.getVerseCount(surahId);
      if (verseCount == 0) return null;

      final verseNumber = random.nextInt(verseCount) + 1;

      final response = await _localDataSource.getSurah(surahId.toString());
      if (response.chapters.isEmpty) return null;

      VerseModel? verse;
      for (final v in response.chapters) {
        if (v.verseNumber == verseNumber) {
          verse = v;
          break;
        }
      }
      if (verse == null) return null;

      return RandomVerseData(
        verseId: 0,
        chapterId: surahId,
        verseNumber: verseNumber,
        verseKey: '$surahId:$verseNumber',
        arabicText: verse.arabicText,
        englishText: '',
      );
    } catch (e, s) {
      Logger.warning(
        'Failed to fetch local random verse: $e',
        feature: 'RandomVerse',
        stackTrace: s,
      );
      return null;
    }
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ').trim();
  }
}

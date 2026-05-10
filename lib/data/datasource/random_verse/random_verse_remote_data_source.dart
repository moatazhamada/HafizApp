import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

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

  RandomVerseRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<RandomVerseData?> fetchRandomVerse() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.quranComBase}/verses/random',
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

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ').trim();
  }
}

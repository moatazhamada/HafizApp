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
        },
      );

      final verse = response.data['verse'] as Map<String, dynamic>?;
      if (verse == null) return null;

      final words =
          (verse['words'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final arabicText = words.map((w) => w['text_uthmani'] ?? '').join(' ');

      // Translation text comes via the verse.translations array.
      final translations = (verse['translations'] as List?)
          ?.cast<Map<String, dynamic>>();
      final englishText = (translations != null && translations.isNotEmpty)
          ? _cleanText(translations[0]['text'] as String? ?? '')
          : '';

      return RandomVerseData(
        verseId: verse['id'] as int? ?? 0,
        chapterId: verse['chapter_id'] as int? ?? 1,
        verseNumber: verse['verse_number'] as int? ?? 1,
        verseKey: verse['verse_key'] as String? ?? '',
        arabicText: arabicText.isNotEmpty
            ? arabicText
            : verse['text_uthmani'] as String? ?? '',
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

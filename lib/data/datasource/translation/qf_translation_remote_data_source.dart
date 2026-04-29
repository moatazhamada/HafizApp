import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Fetches verse translations from QF Content API.
class QfTranslationRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfTranslationRemoteDataSource({required Dio dio, QfApiConfig? config})
    : _dio = dio,
      _config = config ?? const QfApiConfig();

  /// Fetches translations for all verses in a chapter.
  /// Returns `Map<verseNumber, translationText>`.
  Future<Map<int, String>> getTranslationsByChapter(int surahId) async {
    try {
      final response = await _dio.get(
        '${_config.apiBaseUrl}/content/v1/translations/131/by_chapter/$surahId',
      );
      // Response format: { translations: [ { verse_key: "1:1", text: "...", ... }, ... ] }
      // OR it might be: { verses: [ { verse_key: "1:1", translations: [ { text: "..." } ] } ] }
      // Handle both formats
      final Map<int, String> result = {};

      // Try format 1: translations array at top level
      final translations = response.data['translations'] as List?;
      if (translations != null) {
        for (final t in translations) {
          final verseKey = t['verse_key'] as String? ?? '';
          final verseNumber = int.tryParse(verseKey.split(':').last) ?? 0;
          final text = _cleanText(t['text'] as String? ?? '');
          if (verseNumber > 0) result[verseNumber] = text;
        }
        return result;
      }

      // Try format 2: verses array with nested translations
      final verses = response.data['verses'] as List?;
      if (verses != null) {
        for (final v in verses) {
          final verseKey = v['verse_key'] as String? ?? '';
          final verseNumber = int.tryParse(verseKey.split(':').last) ?? 0;
          final translationsList = v['translations'] as List?;
          if (translationsList != null && translationsList.isNotEmpty) {
            final text = _cleanText(
              translationsList[0]['text'] as String? ?? '',
            );
            if (verseNumber > 0) result[verseNumber] = text;
          }
        }
        return result;
      }

      return result;
    } catch (e) {
      Logger.warning(
        'Failed to fetch translations for surah $surahId: $e',
        feature: 'Translation',
      );
      return {};
    }
  }

  String _cleanText(String text) {
    // Strip HTML tags (same as tafsir cleaning)
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class VerseStudyData {
  final String arabicText;
  final String translation;
  final String tafsir;

  const VerseStudyData({
    required this.arabicText,
    required this.translation,
    required this.tafsir,
  });
}

abstract class QfVerseStudyRemoteDataSource {
  Future<VerseStudyData> getVerseStudy(String verseKey);
}

class QfVerseStudyRemoteDataSourceImpl implements QfVerseStudyRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfVerseStudyRemoteDataSourceImpl({required Dio dio, QfApiConfig? config})
    : _dio = dio,
      _config = config ?? const QfApiConfig();

  @override
  Future<VerseStudyData> getVerseStudy(String verseKey) async {
    String arabicText = '';
    String translation = '';
    String tafsir = '';

    try {
      final verseResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/v1/quran/verses/by_key/$verseKey',
        queryParameters: {'words': 'false'},
      );
      final verses = verseResponse.data['verses'] as List?;
      if (verses != null && verses.isNotEmpty) {
        arabicText =
            verses[0]['text_uthmani'] as String? ??
            verses[0]['text'] as String? ??
            '';
      }
    } catch (e) {
      Logger.warning('Failed to fetch verse text: $e', feature: 'VerseStudy');
    }

    try {
      final translationResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/v1/translations/131/by_ayah/$verseKey',
      );
      final translations = translationResponse.data['translations'] as List?;
      if (translations != null && translations.isNotEmpty) {
        translation = translations[0]['text'] as String? ?? '';
      }
    } catch (e) {
      Logger.warning('Failed to fetch translation: $e', feature: 'VerseStudy');
    }

    try {
      final tafsirResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/v1/tafsirs/en-tafsir-ibn-kathir/by_ayah/$verseKey',
      );
      final tafsirData = tafsirResponse.data['tafsir'] as Map<String, dynamic>?;
      if (tafsirData != null) {
        tafsir = tafsirData['text'] as String? ?? '';
      } else {
        final verses = tafsirResponse.data['verses'] as List?;
        if (verses != null && verses.isNotEmpty) {
          final tafsirList = verses[0]['tafsirs'] as List?;
          if (tafsirList != null && tafsirList.isNotEmpty) {
            tafsir = tafsirList[0]['text'] as String? ?? '';
          }
        }
      }
    } catch (e) {
      Logger.warning('Failed to fetch tafsir: $e', feature: 'VerseStudy');
    }

    if (arabicText.isEmpty && translation.isEmpty && tafsir.isEmpty) {
      throw Exception('No data found for verse $verseKey');
    }

    return VerseStudyData(
      arabicText: arabicText,
      translation: translation,
      tafsir: tafsir,
    );
  }
}

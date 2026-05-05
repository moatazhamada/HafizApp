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
    final results = await Future.wait([
      _fetchArabic(verseKey),
      _fetchTranslation(verseKey),
      _fetchTafsir(verseKey),
    ]);

    final arabicText = results[0];
    final translation = results[1];
    final tafsir = results[2];

    if (arabicText.isEmpty && translation.isEmpty && tafsir.isEmpty) {
      throw Exception('No data found for verse $verseKey');
    }

    return VerseStudyData(
      arabicText: arabicText,
      translation: translation,
      tafsir: tafsir,
    );
  }

  Future<String> _fetchArabic(String verseKey) async {
    try {
      final verseResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/api/v4/quran/verses/by_key/$verseKey',
      );
      final verses = verseResponse.data['verses'] as List?;
      if (verses != null && verses.isNotEmpty) {
        return verses[0]['text_uthmani'] as String? ?? '';
      }
    } catch (e) {
      Logger.warning(
        'Failed to fetch verse by key $verseKey: $e',
        feature: 'VerseStudy',
      );
    }
    return '';
  }

  Future<String> _fetchTranslation(String verseKey) async {
    try {
      final translationResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/api/v4/translations/131/by_ayah/$verseKey',
      );
      final translations = translationResponse.data['translations'] as List?;
      if (translations != null && translations.isNotEmpty) {
        return translations[0]['text'] as String? ?? '';
      }
    } catch (e) {
      Logger.warning('Failed to fetch translation: $e', feature: 'VerseStudy');
    }
    return '';
  }

  Future<String> _fetchTafsir(String verseKey) async {
    try {
      final tafsirResponse = await _dio.get(
        '${_config.apiBaseUrl}/content/api/v4/tafsirs/en-tafsir-ibn-kathir/by_ayah/$verseKey',
      );
      final tafsirData = tafsirResponse.data['tafsir'] as Map<String, dynamic>?;
      if (tafsirData != null) {
        final text = tafsirData['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }

      final tafsirs = tafsirResponse.data['tafsirs'] as List?;
      if (tafsirs != null && tafsirs.isNotEmpty) {
        final text = tafsirs[0]['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }
    } catch (e) {
      Logger.warning('Failed to fetch tafsir: $e', feature: 'VerseStudy');
    }
    return '';
  }
}

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';
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
  Future<VerseStudyData> getVerseStudy(
    String verseKey, {
    String? tafsirId,
    String? translationId,
  });

  Future<List<Map<String, dynamic>>> getAvailableTafsirs(String languageCode);

  Future<List<Map<String, dynamic>>> getAvailableTranslations(
    String languageCode,
  );
}

class QfVerseStudyRemoteDataSourceImpl implements QfVerseStudyRemoteDataSource {
  final Dio _dio;

  QfVerseStudyRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<VerseStudyData> getVerseStudy(
    String verseKey, {
    String? tafsirId,
    String? translationId,
  }) async {
    final results = await Future.wait([
      _fetchArabic(verseKey),
      _fetchTranslation(verseKey, translationId: translationId),
      _fetchTafsir(verseKey, tafsirId: tafsirId),
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

  @override
  Future<List<Map<String, dynamic>>> getAvailableTafsirs(
    String languageCode,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contentBase}/resources/tafsirs',
        queryParameters: {'language': languageCode},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final tafsirs = data['tafsirs'] as List?;
        if (tafsirs != null) {
          return tafsirs.whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (e) {
      Logger.warning(
        'Failed to fetch available tafsirs: $e',
        feature: 'VerseStudy',
      );
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableTranslations(
    String languageCode,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.contentBase}/resources/translations',
        queryParameters: {'language': languageCode},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final translations = data['translations'] as List?;
        if (translations != null) {
          return translations.whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (e) {
      Logger.warning(
        'Failed to fetch available translations: $e',
        feature: 'VerseStudy',
      );
    }
    return [];
  }

  Future<String> _fetchArabic(String verseKey) async {
    try {
      final verseResponse = await _dio.get(
        '${ApiConfig.contentBase}/verses/by_key/$verseKey',
        queryParameters: {'fields': 'text_uthmani'},
      );
      final verse = verseResponse.data['verse'] as Map<String, dynamic>?;
      if (verse != null) {
        return verse['text_uthmani'] as String? ?? '';
      }
    } catch (e) {
      Logger.warning(
        'Failed to fetch verse by key $verseKey: $e',
        feature: 'VerseStudy',
      );
    }
    return '';
  }

  Future<String> _fetchTranslation(
    String verseKey, {
    String? translationId,
  }) async {
    if (_isArabicLocale()) return '';

    try {
      final id = translationId ?? ApiConfig.translationId.toString();
      final translationResponse = await _dio.get(
        '${ApiConfig.contentBase}/verses/by_key/$verseKey',
        queryParameters: {
          'translations': id,
          'fields': 'text_uthmani',
        },
      );
      final verse = translationResponse.data['verse'] as Map<String, dynamic>?;
      if (verse != null) {
        final translations = verse['translations'] as List?;
        if (translations != null && translations.isNotEmpty) {
          final text = translations[0]['text'] as String? ?? '';
          return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        }
      }
    } catch (e) {
      Logger.warning('Failed to fetch translation: $e', feature: 'VerseStudy');
    }
    return '';
  }

  Future<String> _fetchTafsir(
    String verseKey, {
    String? tafsirId,
  }) async {
    try {
      final id = tafsirId ?? ApiConfig.tafsirId;
      final tafsirResponse = await _dio.get(
        '${ApiConfig.contentBase}/tafsirs/$id/by_ayah/$verseKey',
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

  bool _isArabicLocale() {
    try {
      return LocaleController.notifier.value.languageCode == 'ar';
    } catch (e) {
      Logger.warning('Failed to detect Arabic locale: $e', feature: 'VerseStudy');
      return false;
    }
  }
}

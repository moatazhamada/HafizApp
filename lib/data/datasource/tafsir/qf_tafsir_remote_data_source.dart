import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class QfTafsirRemoteDataSource {
  Future<String> getTafsirForVerse(String verseKey, {String tafsirId});
}

class QfTafsirRemoteDataSourceImpl implements QfTafsirRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfTafsirRemoteDataSourceImpl({required Dio dio, QfApiConfig? config})
    : _dio = dio,
      _config = config ?? const QfApiConfig();

  @override
  Future<String> getTafsirForVerse(
    String verseKey, {
    String tafsirId = 'en-tafsir-ibn-kathir',
  }) async {
    try {
      final response = await _dio.get(
        '${_config.apiBaseUrl}/content/v1/tafsirs/$tafsirId/by_ayah/$verseKey',
      );

      final tafsir = response.data['tafsir'] as Map<String, dynamic>?;
      if (tafsir != null) {
        final text = tafsir['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }

      final verses = response.data['verses'] as List?;
      if (verses != null && verses.isNotEmpty) {
        final tafsirList = verses[0]['tafsirs'] as List?;
        if (tafsirList != null && tafsirList.isNotEmpty) {
          return tafsirList[0]['text'] as String? ?? '';
        }
      }

      throw Exception('No tafsir found for $verseKey');
    } catch (e) {
      Logger.error('QF tafsir failed for $verseKey: $e', feature: 'QfTafsir');
      rethrow;
    }
  }
}

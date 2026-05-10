import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';

abstract class TafsirRemoteDataSource {
  Future<String> getTafsir(int surahNumber, int verseNumber);
}

class TafsirRemoteDataSourceImpl implements TafsirRemoteDataSource {
  final Dio dio;

  TafsirRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> getTafsir(int surahNumber, int verseNumber) async {
    final response = await dio.get(
      '/verses/by_key/$surahNumber:$verseNumber',
      queryParameters: {
        'translations': ApiConfig.tafsirId,
        'fields': 'text_uthmani',
      },
    );

    // /verses/by_key/{key} returns { "verse": {...} } (singular), not "verses" (plural).
    final verse = response.data['verse'] as Map<String, dynamic>?;
    if (verse == null) {
      throw Exception('No tafsir found');
    }

    final translations = verse['translations'] as List?;
    if (translations == null || translations.isEmpty) {
      throw Exception('No translation found');
    }

    return translations[0]['text'] as String? ?? '';
  }
}

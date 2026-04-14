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
      '/verses/by_key/${surahNumber}:$verseNumber',
      queryParameters: {
        'translations': '169', // Ibn Kathir English (169)
        'fields': 'text_uthmani',
      },
    );

    final verses = response.data['verses'] as List?;
    if (verses == null || verses.isEmpty) {
      throw Exception('No tafsir found');
    }

    final translations = verses[0]['translations'] as List?;
    if (translations == null || translations.isEmpty) {
      throw Exception('No translation found');
    }

    return translations[0]['text'] as String? ?? '';
  }
}

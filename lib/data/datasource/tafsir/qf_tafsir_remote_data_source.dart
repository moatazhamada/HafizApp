import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class QfTafsirRemoteDataSource {
  Future<String> getTafsirForVerse(String verseKey, {String tafsirId});
  Future<Map<int, String>> getTafsirsByChapter(int chapterId, {String tafsirId});
}

class QfTafsirRemoteDataSourceImpl implements QfTafsirRemoteDataSource {
  final Dio _dio;

  QfTafsirRemoteDataSourceImpl({required Dio dio})
    : _dio = dio;

  @override
  Future<String> getTafsirForVerse(
    String verseKey, {
    String tafsirId = '169',
  }) async {
    try {
      final response = await _dio.get(
        '$ApiConfig.quranComBase/tafsirs/$tafsirId/by_ayah/$verseKey',
      );

      final tafsir = response.data['tafsir'] as Map<String, dynamic>?;
      if (tafsir != null) {
        final text = tafsir['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }

      final tafsirs = response.data['tafsirs'] as List?;
      if (tafsirs != null && tafsirs.isNotEmpty) {
        final text = tafsirs[0]['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }

      throw Exception('No tafsir found for $verseKey');
    } catch (e) {
      Logger.error('QF tafsir failed for $verseKey: $e', feature: 'QfTafsir');
      rethrow;
    }
  }

  @override
  Future<Map<int, String>> getTafsirsByChapter(
    int chapterId, {
    String tafsirId = '169',
  }) async {
    try {
      final allItems = await _fetchAllPages((page) => _dio.get(
        '$ApiConfig.quranComBase/tafsirs/$tafsirId/by_chapter/$chapterId',
        queryParameters: {'per_page': 50, 'page': page},
      ), 'tafsirs');

      final Map<int, String> result = {};
      for (final item in allItems) {
        final verseKey = item['verse_key'] as String? ?? '';
        final verseNumber = int.tryParse(verseKey.split(':').last) ?? 0;
        final text = item['text'] as String? ?? '';
        if (verseNumber > 0 && text.isNotEmpty) {
          result[verseNumber] = text;
        }
      }
      return result;
    } catch (e) {
      Logger.error(
        'QF tafsir chapter $chapterId failed: $e',
        feature: 'QfTafsir',
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllPages(
    Future<Response> Function(int page) fetchPage,
    String itemsKey,
  ) async {
    final allItems = <Map<String, dynamic>>[];
    int page = 1;
    int? totalPages = 1;

    while (page <= (totalPages ?? 1)) {
      final response = await fetchPage(page);
      final data = response.data as Map<String, dynamic>;

      final items = (data[itemsKey] ?? []) as List;
      allItems.addAll(items.cast<Map<String, dynamic>>());

      final pagination = data['pagination'];
      if (pagination != null) {
        totalPages = pagination['total_pages'] as int?;
      } else {
        break;
      }
      page++;
    }

    return allItems;
  }
}

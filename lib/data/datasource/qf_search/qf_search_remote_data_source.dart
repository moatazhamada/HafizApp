import 'package:dio/dio.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Remote data source for online Quran search.
///
/// Uses the Quran.com v4 public search API (`GET /search`).
/// Supports Arabic text search and English translation search.
/// No authentication required.
abstract class QfSearchRemoteDataSource {
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int? size,
    int? page,
    String? language,
  });
}

class QfSearchRemoteDataSourceImpl implements QfSearchRemoteDataSource {
  final Dio _dio;

  QfSearchRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int? size,
    int? page,
    String? language,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'size': size ?? 20,
        'page': page ?? 1,
      };
      if (language != null) queryParams['language'] = language;

      final response = await _dio.get('/search', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        // Quran.com v4 wraps results in { search: { results: [...] } }
        final searchWrapper = data['search'];
        if (searchWrapper is Map<String, dynamic>) {
          final results = searchWrapper['results'];
          if (results is List) {
            return results.cast<Map<String, dynamic>>();
          }
        }
        // Fallback: flat results list
        final results = data['results'] ?? data['hits'] ?? data['data'] ?? [];
        if (results is List) {
          return results.cast<Map<String, dynamic>>();
        }
        return [];
      }
      return [];
    } catch (e) {
      Logger.warning('Online search failed: $e', feature: 'Search');
      return [];
    }
  }
}

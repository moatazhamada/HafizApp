import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
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
  late final Dio _dio;

  QfSearchRemoteDataSourceImpl({Dio? dio}) {
    // Use a dedicated Dio instance pointing to Quran.com public API
    // so search works independently of auth-protected QF APIs.
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: ApiConfig.quranComBase,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

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

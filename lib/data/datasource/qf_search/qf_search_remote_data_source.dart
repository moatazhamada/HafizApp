import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Remote data source for QF Search API (semantic search).
///
/// Endpoint: GET /api/v1/search
///
/// Provides server-side search across Quran content with relevance scoring.
/// Used as a fallback for natural language / semantic queries that the local
/// text-matching search cannot handle well.
abstract class QfSearchRemoteDataSource {
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int? size,
    String? language,
  });
}

class QfSearchRemoteDataSourceImpl implements QfSearchRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfSearchRemoteDataSourceImpl({
    required Dio dio,
    QfApiConfig? config,
  })  : _dio = dio,
        _config = config ?? const QfApiConfig();

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int? size,
    String? language,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
      };
      if (size != null) queryParams['size'] = size;
      if (language != null) queryParams['language'] = language;

      final response = await _dio.get(
        '${_config.apiBaseUrl}/api/v1/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Response format: { results: [{ verse_key, text, highlight, ... }] }
        // or { hits: [...] } depending on version
        final data = response.data;
        final results = data['results'] ?? data['hits'] ?? data['data'] ?? [];
        if (results is List) {
          return results.cast<Map<String, dynamic>>();
        }
        return [];
      }
      return [];
    } catch (e) {
      Logger.warning('QF search failed: $e', feature: 'QfSearch');
      return [];
    }
  }
}

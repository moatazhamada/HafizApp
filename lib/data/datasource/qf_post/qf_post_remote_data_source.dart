import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class QfPostRemoteDataSource {
  Future<Map<String, dynamic>?> createReflection({
    required String verseKey,
    required String text,
  });
  Future<List<Map<String, dynamic>>> getReflections(String verseKey);
  Future<void> deletePost(String postId);
}

class QfPostRemoteDataSourceImpl implements QfPostRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfPostRemoteDataSourceImpl({
    required Dio dio,
    QfApiConfig? config,
  })  : _dio = dio,
        _config = config ?? const QfApiConfig();

  String get _baseUrl => '${_config.apiBaseUrl}/auth/v1';

  @override
  Future<Map<String, dynamic>?> createReflection({
    required String verseKey,
    required String text,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/posts',
        data: {
          'text': text,
          'verseKey': verseKey,
          'type': 'REFLECTION',
        },
        options: Options(
          headers: {'x-timezone': DateTime.now().timeZoneName},
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Logger.info('Created reflection for $verseKey', feature: 'QfPost');
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Logger.warning('Failed to create reflection: $e', feature: 'QfPost');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getReflections(String verseKey) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/posts',
        queryParameters: {'verseKey': verseKey, 'first': 50},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.warning('Failed to get reflections: $e', feature: 'QfPost');
      return [];
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('$_baseUrl/posts/$postId');
      Logger.info('Deleted post $postId', feature: 'QfPost');
    } catch (e) {
      Logger.warning('Failed to delete post: $e', feature: 'QfPost');
    }
  }
}

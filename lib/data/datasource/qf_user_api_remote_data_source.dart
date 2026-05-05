import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class QfUserApiRemoteDataSource {
  Future<List<dynamic>> getCollections();
  Future<Map<String, dynamic>?> createCollection(String name);
  Future<List<dynamic>> getBookmarks();
  Future<void> addBookmark(int verseId, {String? collectionId});
  Future<void> removeBookmark(int verseId);
}

class QfUserApiRemoteDataSourceImpl implements QfUserApiRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;

  QfUserApiRemoteDataSourceImpl({required Dio dio, QfApiConfig? config})
      : _dio = dio,
        _config = config ?? const QfApiConfig();

  @override
  Future<List<dynamic>> getCollections() async {
    try {
      final response = await _dio.get(
        '${_config.apiBaseUrl}/auth/v1/collections?first=50',
      );
      if (response.statusCode == 200) {
        return response.data['collections'] ?? [];
      }
      return [];
    } catch (e) {
      Logger.error('Failed to get QF collections: $e', feature: 'QfUserApi');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> createCollection(String name) async {
    try {
      final response = await _dio.post(
        '${_config.apiBaseUrl}/auth/v1/collections',
        data: {'name': name},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Logger.error('Failed to create QF collection: $e', feature: 'QfUserApi');
      return null;
    }
  }

  @override
  Future<List<dynamic>> getBookmarks() async {
    try {
      final response = await _dio.get(
        '${_config.apiBaseUrl}/auth/v1/bookmarks?first=100',
      );
      if (response.statusCode == 200) {
        return response.data['bookmarks'] ?? [];
      }
      return [];
    } catch (e) {
      Logger.error('Failed to get QF bookmarks: $e', feature: 'QfUserApi');
      rethrow;
    }
  }

  @override
  Future<void> addBookmark(int verseId, {String? collectionId}) async {
    try {
      final data = <String, dynamic>{
        'verse_id': verseId,
      };
      if (collectionId != null) {
        data['collection_id'] = collectionId;
      }
      await _dio.post(
        '${_config.apiBaseUrl}/auth/v1/bookmarks',
        data: data,
      );
    } catch (e) {
      Logger.error('Failed to add QF bookmark: $e', feature: 'QfUserApi');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(int verseId) async {
    try {
      // Assuming DELETE accepts verse_id or bookmark_id. 
      // Adjust according to the actual field reference in QF docs.
      await _dio.delete(
        '${_config.apiBaseUrl}/auth/v1/bookmarks/$verseId',
      );
    } catch (e) {
      Logger.error('Failed to remove QF bookmark: $e', feature: 'QfUserApi');
      rethrow;
    }
  }
}

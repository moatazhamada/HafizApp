import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

abstract class NetworkManagerI {
  Future<Response> get(String url, {Map<String, dynamic>? params});

  Future<Response> post(String url, {Map<String, dynamic>? data});

  Future<Response> put(String url, {Map<String, dynamic>? data});

  Future<Response> delete(String url, {Map<String, dynamic>? data});
}

class NetworkManagerImpl extends NetworkManagerI {
  final Dio _dio;

  /// In-flight requests for deduplication
  final Map<String, Future<Response>> _inFlightRequests = {};

  NetworkManagerImpl(this._dio) {
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  /// Generate a cache key from URL and params
  String _getCacheKey(String url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return url;
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$url?${sortedParams.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  @override
  Future<Response> get(String url, {Map<String, dynamic>? params}) async {
    final cacheKey = _getCacheKey(url, params);

    // Return existing in-flight request if one exists (deduplication)
    // This is safe in Dart's single-threaded model - the check and put are synchronous
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    // Create the request future and store it atomically (before any await)
    final requestFuture = _executeGet(url, params);
    _inFlightRequests[cacheKey] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      // Clean up after request completes (success or failure)
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<Response> _executeGet(String url, Map<String, dynamic>? params) async {
    try {
      // Accept non-2xx and let callers decide. Avoid Dio throwing on 4xx/5xx.
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(validateStatus: (_) => true),
      );
      return response;
    } on DioException {
      // Preserve DioException so upstream can handle gracefully.
      rethrow;
    }
  }

  @override
  Future<Response> post(String url, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(validateStatus: (_) => true),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Response> put(String url, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        options: Options(validateStatus: (_) => true),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<Response> delete(String url, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.delete(
        url,
        data: data,
        options: Options(validateStatus: (_) => true),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }
}

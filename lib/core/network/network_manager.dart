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

  NetworkManagerImpl(this._dio) {
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  @override
  Future<Response> get(String url, {Map<String, dynamic>? params}) async {
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

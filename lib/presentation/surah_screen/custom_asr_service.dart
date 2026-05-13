import 'package:dio/dio.dart';
import 'package:hafiz_app/core/utils/logger.dart';

import '../../core/network/debug_log_interceptor.dart';

class CustomAsrService {
  final Dio _dio;

  CustomAsrService([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ) {
    if (dio == null) _dio.interceptors.add(DebugLogInterceptor());
  }

  Future<String?> transcribe({
    required String endpoint,
    required String filePath,
    String language = 'ar',
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath),
        'language': language,
      });
      final resp = await _dio.post(endpoint, data: formData);
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data['text']?.toString() ??
            data['transcript']?.toString() ??
            data['result']?.toString();
      }
    } catch (e) {
      Logger.warning('Custom ASR failed: $e', feature: 'CustomASR');
    }
    return null;
  }
}

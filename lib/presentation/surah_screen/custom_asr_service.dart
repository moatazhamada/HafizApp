import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CustomAsrService {
  final Dio _dio;

  CustomAsrService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ));

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
      debugPrint('Custom ASR failed: $e');
    }
    return null;
  }
}

import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/api_config.dart';
import '../network/debug_log_interceptor.dart';
import '../network/qf_auth.dart';
import 'recitation_models.dart';

class RecitationService {
  final Dio _dio;
  static final Map<String, ChapterAudioFile> _audioCache = {};

  RecitationService([Dio? dio]) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.useQfContent
            ? ApiConfig.qfContentBase
            : ApiConfig.quranComBase,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    dio.interceptors.add(DebugLogInterceptor());
    if (ApiConfig.clientId.isNotEmpty && ApiConfig.clientSecret.isNotEmpty) {
      dio.interceptors.add(QfAuthInterceptor(QfAuthService()));
    }
    return dio;
  }

  Future<List<Reciter>> fetchReciters() async {
    try {
      final resp = await _dio.get('/resources/recitations');
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final list = data['recitations'] ?? data['data'];
        if (list is List) {
          return list
              .map((e) => Reciter.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (data is List) {
        return data
            .map((e) => Reciter.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch reciters: $e');
    }
    return _fallbackReciters();
  }

  Future<ChapterAudioFile?> fetchChapterAudio({
    required int reciterId,
    required int chapterNumber,
    bool segments = true,
  }) async {
    final cacheKey = '$reciterId:$chapterNumber:${segments ? 1 : 0}';
    final cached = _audioCache[cacheKey];
    if (cached != null) return cached;
    final cachedHive = _readCachedAudio(cacheKey);
    if (cachedHive != null) {
      _audioCache[cacheKey] = cachedHive;
      return cachedHive;
    }
    try {
      final resp = await _dio.get(
        '/chapter_recitations/$reciterId/$chapterNumber',
        queryParameters: {'segments': segments ? 'true' : 'false'},
      );
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final audioFile = data['audio_file'] ?? data['chapter_recitation'];
        if (audioFile is Map<String, dynamic>) {
          final parsed = ChapterAudioFile.fromJson(audioFile);
          _audioCache[cacheKey] = parsed;
          _writeCachedAudio(cacheKey, parsed);
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch chapter audio: $e');
    }
    return null;
  }

  ChapterAudioFile? _readCachedAudio(String key) {
    if (!Hive.isBoxOpen('audio_cache')) return null;
    final box = Hive.box('audio_cache');
    final raw = box.get('audio_$key');
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return ChapterAudioFile.fromJson(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  void _writeCachedAudio(String key, ChapterAudioFile audio) {
    if (!Hive.isBoxOpen('audio_cache')) return;
    final box = Hive.box('audio_cache');
    box.put('audio_$key', jsonEncode(audio.toJson()));
  }

  List<Reciter> _fallbackReciters() {
    return const [
      Reciter(id: 7, name: 'Mishary Alafasy'),
      Reciter(id: 1, name: 'Abdul Basit'),
      Reciter(id: 2, name: 'Husary'),
    ];
  }
}

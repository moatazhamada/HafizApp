import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/api_config.dart';
import '../network/qf_auth.dart';
import 'quran_word_models.dart';

/// Service for fetching word-level Quran data from QF Content API.
/// Provides per-word text, transliteration, and audio URLs.
class QuranWordService {
  final Dio _dio;
  static final Map<String, VerseWordData> _memoryCache = {};

  QuranWordService([Dio? dio])
      : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.useQfContent
          ? ApiConfig.qfContentBase
          : ApiConfig.quranComBase,
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 12),
    ));
    if (ApiConfig.clientId.isNotEmpty && ApiConfig.clientSecret.isNotEmpty) {
      dio.interceptors.add(QfAuthInterceptor(QfAuthService()));
    }
    return dio;
  }

  /// Fetch word-level data for a single verse.
  /// Returns cached data if available (memory → Hive → network).
  Future<VerseWordData?> fetchVerseWords(String verseKey) async {
    final cacheKey = 'words_$verseKey';

    // Memory cache
    final cached = _memoryCache[cacheKey];
    if (cached != null) return cached;

    // Hive cache
    final hiveCached = _readCached(cacheKey);
    if (hiveCached != null) {
      _memoryCache[cacheKey] = hiveCached;
      return hiveCached;
    }

    // Network fetch
    try {
      final resp = await _dio.get(
        '/verses/by_key/$verseKey',
        queryParameters: {
          'words': 'true',
          'word_fields':
              'text_uthmani,transliteration,audio_url,position,char_type_name',
        },
      );
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final verse = data['verse'];
        if (verse is Map<String, dynamic>) {
          final wordData = VerseWordData.fromJson(verse);
          _memoryCache[cacheKey] = wordData;
          _writeCached(cacheKey, wordData);
          return wordData;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch verse words for $verseKey: $e');
    }
    return null;
  }

  /// Fetch word-level data for an entire chapter.
  Future<Map<String, VerseWordData>> fetchChapterWords(
    int chapterNumber,
  ) async {
    final results = <String, VerseWordData>{};

    try {
      final resp = await _dio.get(
        '/verses/by_chapter/$chapterNumber',
        queryParameters: {
          'words': 'true',
          'word_fields':
              'text_uthmani,transliteration,audio_url,position,char_type_name',
          'per_page': '300',
        },
      );
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final verses = data['verses'];
        if (verses is List) {
          for (final v in verses) {
            if (v is Map<String, dynamic>) {
              final wordData = VerseWordData.fromJson(v);
              results[wordData.verseKey] = wordData;
              final cacheKey = 'words_${wordData.verseKey}';
              _memoryCache[cacheKey] = wordData;
              _writeCached(cacheKey, wordData);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch chapter words for $chapterNumber: $e');
    }
    return results;
  }

  /// Get transliteration for a specific word position in a verse.
  Future<String?> getTransliteration(String verseKey, int wordPosition) async {
    final data = await fetchVerseWords(verseKey);
    return data?.transliterationAt(wordPosition);
  }

  /// Get audio URL for a specific word position in a verse.
  Future<String?> getWordAudioUrl(String verseKey, int wordPosition) async {
    final data = await fetchVerseWords(verseKey);
    return data?.audioUrlAt(wordPosition);
  }

  VerseWordData? _readCached(String key) {
    if (!Hive.isBoxOpen('quran_word_cache')) return null;
    final box = Hive.box('quran_word_cache');
    final raw = box.get(key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return VerseWordData.fromJson(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  void _writeCached(String key, VerseWordData data) {
    if (!Hive.isBoxOpen('quran_word_cache')) return;
    final box = Hive.box('quran_word_cache');
    box.put(key, jsonEncode(data.toJson()));
  }
}

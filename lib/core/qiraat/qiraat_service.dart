import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/api_config.dart';
import 'qiraat_models.dart';

class QiraatService {
  final Dio _dio;
  static List<QiraatEdition>? _editionsCache;
  static final Map<String, String> _ayahCache = {};

  QiraatService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.quranHubBase,
              connectTimeout: const Duration(seconds: 7),
              receiveTimeout: const Duration(seconds: 12),
            ));

  Future<List<QiraatEdition>> fetchEditions() async {
    if (_editionsCache != null && _editionsCache!.isNotEmpty) {
      return _editionsCache!;
    }
    final cached = _readCachedEditions();
    if (cached.isNotEmpty) {
      _editionsCache = cached;
      return _editionsCache!;
    }
    try {
      final resp = await _dio.get('/edition');
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['editions'];
        if (list is List) {
          _editionsCache = list
              .map((e) => QiraatEdition.fromJson(e as Map<String, dynamic>))
              .toList();
          _writeCachedEditions(_editionsCache!);
          return _editionsCache!;
        }
      } else if (data is List) {
        _editionsCache = data
            .map((e) => QiraatEdition.fromJson(e as Map<String, dynamic>))
            .toList();
        _writeCachedEditions(_editionsCache!);
        return _editionsCache!;
      }
    } catch (e) {
      debugPrint('Failed to fetch editions: $e');
    }
    _editionsCache ??= _fallbackEditions();
    return _editionsCache!;
  }

  Future<String?> fetchAyahText({
    required int surahId,
    required int verseNumber,
    required String edition,
  }) async {
    final key = '$edition:$surahId:$verseNumber';
    final cached = _ayahCache[key];
    if (cached != null && cached.isNotEmpty) return cached;
    final cachedHive = _readCachedAyah(key);
    if (cachedHive != null && cachedHive.isNotEmpty) {
      _ayahCache[key] = cachedHive;
      return cachedHive;
    }
    try {
      final ref = '$surahId:$verseNumber';
      final resp = await _dio.get('/ayah/$ref/editions/$edition');
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final ayahData = data['data'];
        if (ayahData is List && ayahData.isNotEmpty) {
          final ayah = QiraatAyah.fromJson(
              ayahData.first as Map<String, dynamic>);
          _ayahCache[key] = ayah.text;
          _writeCachedAyah(key, ayah.text);
          return ayah.text;
        } else if (ayahData is Map<String, dynamic>) {
          final ayah = QiraatAyah.fromJson(ayahData);
          _ayahCache[key] = ayah.text;
          _writeCachedAyah(key, ayah.text);
          return ayah.text;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch ayah text: $e');
    }
    return null;
  }

  List<QiraatEdition> _readCachedEditions() {
    if (!Hive.isBoxOpen('qiraat_cache')) return [];
    final box = Hive.box('qiraat_cache');
    final raw = box.get('editions');
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(QiraatEdition.fromJson)
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  void _writeCachedEditions(List<QiraatEdition> editions) {
    if (!Hive.isBoxOpen('qiraat_cache')) return;
    final box = Hive.box('qiraat_cache');
    final data = editions.map((e) => e.toJson()).toList();
    box.put('editions', jsonEncode(data));
  }

  String? _readCachedAyah(String key) {
    if (!Hive.isBoxOpen('qiraat_cache')) return null;
    final box = Hive.box('qiraat_cache');
    final raw = box.get('ayah_$key');
    return raw is String ? raw : null;
  }

  void _writeCachedAyah(String key, String text) {
    if (!Hive.isBoxOpen('qiraat_cache')) return;
    final box = Hive.box('qiraat_cache');
    box.put('ayah_$key', text);
  }

  List<QiraatEdition> _fallbackEditions() {
    return const [
      QiraatEdition(
        identifier: 'quran-uthmani',
        name: 'Uthmani (Hafs)',
        language: 'ar',
        format: 'text',
        type: 'quran',
      ),
      QiraatEdition(
        identifier: 'quran-simple',
        name: 'Simple',
        language: 'ar',
        format: 'text',
        type: 'quran',
      ),
      QiraatEdition(
        identifier: 'quran-warsh',
        name: 'Warsh',
        language: 'ar',
        format: 'text',
        type: 'quran',
      ),
      QiraatEdition(
        identifier: 'quran-qaloon',
        name: 'Qaloon',
        language: 'ar',
        format: 'text',
        type: 'quran',
      ),
    ];
  }
}

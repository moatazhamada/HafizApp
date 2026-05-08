import 'package:dio/dio.dart';
import 'package:hafiz_app/core/mushaf/mushaf_rendering_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QuranHubAyah {
  final int number;
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final int juz;
  final int page;

  const QuranHubAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    required this.juz,
    required this.page,
  });

  factory QuranHubAyah.fromJson(Map<String, dynamic> json) {
    return QuranHubAyah(
      number: (json['number'] ?? 0) as int,
      text: (json['text'] ?? '') as String,
      numberInSurah: (json['numberInSurah'] ?? 0) as int,
      surahNumber: (json['surah']?['number'] ?? 0) as int,
      juz: (json['juz']?['number'] ?? 0) as int,
      page: (json['page']?['number'] ?? 0) as int,
    );
  }
}

class QuranHubSurah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;

  const QuranHubSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
  });

  factory QuranHubSurah.fromJson(Map<String, dynamic> json) {
    return QuranHubSurah(
      number: (json['number'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      englishName: (json['englishName'] ?? '') as String,
      numberOfAyahs: (json['numberOfAyahs'] ?? 0) as int,
    );
  }
}

class QuranHubPageData {
  final int pageNumber;
  final int topPageJuz;
  final List<QuranHubAyah> ayahs;
  final QuranHubSurah topSurah;
  final String editionId;

  const QuranHubPageData({
    required this.pageNumber,
    required this.topPageJuz,
    required this.ayahs,
    required this.topSurah,
    required this.editionId,
  });

  factory QuranHubPageData.fromJson(
    Map<String, dynamic> json, {
    required int pageNumber,
    required String editionId,
  }) {
    final ayahsRaw = json['ayahs'] as List<dynamic>? ?? [];
    final ayahs = ayahsRaw
        .whereType<Map<String, dynamic>>()
        .map((a) => QuranHubAyah.fromJson(a))
        .toList();

    final surahRaw = json['surah'] as Map<String, dynamic>?;
    final topSurah = surahRaw != null
        ? QuranHubSurah.fromJson(surahRaw)
        : const QuranHubSurah(
            number: 0, name: '', englishName: '', numberOfAyahs: 0);

    return QuranHubPageData(
      pageNumber: pageNumber,
      topPageJuz: (json['juz']?['number'] ?? 0) as int,
      ayahs: ayahs,
      topSurah: topSurah,
      editionId: editionId,
    );
  }
}

abstract class QuranHubPageDataSource {
  Future<QuranHubPageData?> fetchPage(int page, {required String edition});
}

class QuranHubPageDataSourceImpl implements QuranHubPageDataSource {
  final Dio _dio;

  QuranHubPageDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<QuranHubPageData?> fetchPage(int page,
      {required String edition}) async {
    try {
      final url =
          '${MushafRenderingConfig.quranHubApiBase}/page/$page/$edition';
      final response = await _dio.get(url);

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      return QuranHubPageData.fromJson(
        data,
        pageNumber: page,
        editionId: edition,
      );
    } catch (e) {
      Logger.error('Failed to fetch QuranHub page $page/$edition: $e',
          feature: 'Mushaf');
      return null;
    }
  }
}

class CachedQuranHubPageDataSource implements QuranHubPageDataSource {
  final QuranHubPageDataSource _inner;
  final Map<String, QuranHubPageData> _cache = {};
  final List<String> _cacheOrder = [];
  static const int _maxCacheSize = 20;

  CachedQuranHubPageDataSource({required QuranHubPageDataSource inner})
      : _inner = inner;

  String _cacheKey(int page, String edition) => '$page|$edition';

  @override
  Future<QuranHubPageData?> fetchPage(int page,
      {required String edition}) async {
    final key = _cacheKey(page, edition);
    if (_cache.containsKey(key)) {
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
      return _cache[key];
    }

    final data = await _inner.fetchPage(page, edition: edition);
    if (data != null) {
      if (_cache.length >= _maxCacheSize) {
        final oldest = _cacheOrder.removeAt(0);
        _cache.remove(oldest);
      }
      _cache[key] = data;
      _cacheOrder.add(key);
    }
    return data;
  }
}

import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfTranslationRemoteDataSource {
  final Dio _dio;
  final QfApiConfig _config;
  final Map<int, Map<int, String>> _translationCache = {};

  QfTranslationRemoteDataSource({required Dio dio, QfApiConfig? config})
    : _dio = dio,
      _config = config ?? const QfApiConfig();

  Future<Map<int, String>> getTranslationsByChapter(int surahId) async {
    if (_translationCache.containsKey(surahId)) {
      return _translationCache[surahId]!;
    }

    try {
      final allItems = await _fetchAllPages((page) => _dio.get(
        '${_config.apiBaseUrl}/content/api/v4/translations/131/by_chapter/$surahId',
        queryParameters: {'per_page': 50, 'page': page},
      ), 'translations');

      final Map<int, String> result = {};
      if (allItems.isNotEmpty) {
        for (final t in allItems) {
          final verseKey = t['verse_key'] as String? ?? '';
          final verseNumber = int.tryParse(verseKey.split(':').last) ?? 0;
          final text = _cleanText(t['text'] as String? ?? '');
          if (verseNumber > 0) result[verseNumber] = text;
        }
        _translationCache[surahId] = result;
        return result;
      }

      final allVerseItems = await _fetchAllPages((page) => _dio.get(
        '${_config.apiBaseUrl}/content/api/v4/translations/131/by_chapter/$surahId',
        queryParameters: {'per_page': 50, 'page': page},
      ), 'verses');

      if (allVerseItems.isNotEmpty) {
        for (final v in allVerseItems) {
          final verseKey = v['verse_key'] as String? ?? '';
          final verseNumber = int.tryParse(verseKey.split(':').last) ?? 0;
          final text = _cleanText(v['text'] as String? ?? '');
          if (verseNumber > 0 && text.isNotEmpty) result[verseNumber] = text;
        }
        _translationCache[surahId] = result;
        return result;
      }

      return result;
    } catch (e) {
      Logger.warning(
        'Failed to fetch translations for surah $surahId: $e',
        feature: 'Translation',
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllPages(
    Future<Response> Function(int page) fetchPage,
    String itemsKey,
  ) async {
    final allItems = <Map<String, dynamic>>[];
    int page = 1;
    int? totalPages = 1;

    while (page <= (totalPages ?? 1)) {
      final response = await fetchPage(page);
      final data = response.data as Map<String, dynamic>;

      final items = (data[itemsKey] ?? []) as List;
      allItems.addAll(items.cast<Map<String, dynamic>>());

      final pagination = data['pagination'];
      if (pagination != null) {
        totalPages = pagination['total_pages'] as int?;
      } else {
        break;
      }
      page++;
    }

    return allItems;
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

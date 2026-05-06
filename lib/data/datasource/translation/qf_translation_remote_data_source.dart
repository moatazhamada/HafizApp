import 'package:dio/dio.dart';
import 'package:hafiz_app/core/config/api_config.dart';
import 'package:hafiz_app/core/i18n/locale_controller.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Default translation ID for English renderings.
/// 85 = M.A.S. Abdel Haleem (modern, readable English).
/// Valid alternatives: 20 (Saheeh International), 22 (Yusuf Ali), 149 (Bridges).
const int _translationId = 85;

class QfTranslationRemoteDataSource {
  final Dio _dio;
  final Map<int, Map<int, String>> _translationCache = {};

  QfTranslationRemoteDataSource({required Dio dio})
    : _dio = dio;

  /// Returns a verse-number → text map for [surahId].
  /// Only fetches when the current UI locale is **not Arabic**.
  Future<Map<int, String>> getTranslationsByChapter(int surahId) async {
    if (_isArabicLocale()) return {};

    if (_translationCache.containsKey(surahId)) {
      return _translationCache[surahId]!;
    }

    try {
      final allItems = await _fetchAllPages((page) => _dio.get(
        '${ApiConfig.quranComBase}/translations/$_translationId/by_chapter/$surahId',
        queryParameters: {'per_page': 50, 'page': page},
      ), 'translations');

      // API returns items ordered by verse but without a verse_key field.
      // Compute verse number from page offset + position.
      final Map<int, String> result = {};
      if (allItems.isNotEmpty) {
        // allItems is a flat list across all pages; they arrive in order.
        for (int i = 0; i < allItems.length; i++) {
          final text = _cleanText(allItems[i]['text'] as String? ?? '');
          if (text.isNotEmpty) result[i + 1] = text;
        }
        _translationCache[surahId] = result;
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

  bool _isArabicLocale() {
    try {
      return LocaleController.notifier.value.languageCode == 'ar';
    } catch (_) {
      return false;
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
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ').trim();
  }
}

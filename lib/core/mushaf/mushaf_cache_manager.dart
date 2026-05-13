import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class MushafCacheManager {
  static const String _key = 'mushaf_cache';
  static const int _maxCacheObjects = 2500;
  static const Duration _stalePeriod = Duration(days: 30);

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: _maxCacheObjects,
    ),
  );

  /// Generate a cache key that includes the Mushaf type so different
  /// types don't collide.
  static String cacheKey(String mushafType, int pageNumber) {
    return 'mushaf_${mushafType}_$pageNumber';
  }

  /// Clear all cached Mushaf images.
  static Future<void> clearCache() async {
    Logger.info('Clearing Mushaf image cache', feature: 'MushafCache');
    await instance.emptyCache();
  }
}

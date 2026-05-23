import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

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

  /// Get the approximate cache size in MB by walking the cache directory.
  static Future<double> getCacheSizeMB() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_key');
      if (!await cacheDir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      return totalBytes / (1024 * 1024);
    } catch (e, stack) {
      Logger.warning(
        'Failed to compute cache size: $e',
        feature: 'MushafCache',
        stackTrace: stack,
      );
      return 0.0;
    }
  }
}

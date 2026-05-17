import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../model/memorization_progress_model.dart';

abstract class MemorizationLocalDataSource {
  Future<List<MemorizationProgressModel>> getAllProgress();
  Future<MemorizationProgressModel?> getProgress(int surahId);
  Future<void> saveProgress(MemorizationProgressModel progress);
  Future<void> removeProgress(int surahId);
}

class MemorizationLocalDataSourceImpl implements MemorizationLocalDataSource {
  final Box box;

  MemorizationLocalDataSourceImpl({required this.box});

  @override
  Future<List<MemorizationProgressModel>> getAllProgress() async {
    try {
      final List<MemorizationProgressModel> items = [];
      for (final e in box.values) {
        if (e is! Map) continue;
        try {
          items.add(
            MemorizationProgressModel.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (e) {
          Logger.warning('Skipping malformed memorization entry: $e', feature: 'MemorizationLocal');
          continue;
        }
      }
      return items;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<MemorizationProgressModel?> getProgress(int surahId) async {
    try {
      final raw = box.get(surahId);
      if (raw is! Map) return null;
      try {
        return MemorizationProgressModel.fromJson(Map<String, dynamic>.from(raw));
      } catch (e) {
        Logger.warning('Skipping malformed memorization entry for surah $surahId: $e', feature: 'MemorizationLocal');
        return null;
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveProgress(MemorizationProgressModel progress) async {
    try {
      await box.put(progress.surahId, progress.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> removeProgress(int surahId) async {
    try {
      await box.delete(surahId);
    } catch (e) {
      throw CacheException();
    }
  }
}

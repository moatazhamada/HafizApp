import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../model/recitation_error_model.dart';

abstract class RecitationErrorLocalDataSource {
  Future<List<RecitationErrorModel>> getRecitationErrors();
  Future<void> addRecitationError(RecitationErrorModel error);
  Future<void> removeRecitationError(int surahId, int verseId);
  Future<void> clearAll();
}

class RecitationErrorLocalDataSourceImpl
    implements RecitationErrorLocalDataSource {
  final Box box;

  RecitationErrorLocalDataSourceImpl({required this.box});

  @override
  Future<List<RecitationErrorModel>> getRecitationErrors() async {
    try {
      final List<RecitationErrorModel> errors = [];

      for (final e in box.values) {
        if (e is! Map) continue;
        try {
          errors.add(
            RecitationErrorModel.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (e) {
          // Skip malformed entries instead of failing the entire read.
          Logger.warning('Skipping malformed recitation error entry: $e', feature: 'RecitationErrorLocal');
          continue;
        }
      }

      return errors;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> addRecitationError(RecitationErrorModel error) async {
    try {
      final key = '${error.surahId}_${error.verseId}';
      final existingRaw = box.get(key);
      if (existingRaw is Map) {
        final existing = RecitationErrorModel.fromJson(
          Map<String, dynamic>.from(existingRaw),
        );

        final updated = RecitationErrorModel(
          surahId: existing.surahId,
          surahName: existing.surahName,
          verseId: existing.verseId,
          createdAt: existing.createdAt,
          count: existing.count + 1,
        );

        await box.put(key, updated.toJson());
        return;
      }

      await box.put(key, error.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> removeRecitationError(int surahId, int verseId) async {
    try {
      final key = '${surahId}_$verseId';
      await box.delete(key);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await box.clear();
    } catch (e) {
      throw CacheException();
    }
  }
}

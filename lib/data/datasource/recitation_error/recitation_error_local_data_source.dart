import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../model/recitation_error_model.dart';

abstract class RecitationErrorLocalDataSource {
  Future<List<RecitationErrorModel>> getRecitationErrors();
  Future<void> addRecitationError(RecitationErrorModel error);
  Future<void> removeRecitationError(int surahId, int verseId);
}

class RecitationErrorLocalDataSourceImpl
    implements RecitationErrorLocalDataSource {
  final Box box;

  RecitationErrorLocalDataSourceImpl({required this.box});

  @override
  Future<List<RecitationErrorModel>> getRecitationErrors() async {
    try {
      return box.values
          .map(
            (e) => RecitationErrorModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> addRecitationError(RecitationErrorModel error) async {
    try {
      final key = '${error.surahId}_${error.verseId}';
      await box.put(key, error.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> removeRecitationError(int surahId, int verseId) async {
    try {
      final key = '${surahId}_${verseId}';
      await box.delete(key);
    } catch (e) {
      throw CacheException();
    }
  }
}

import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../model/hifz_entry_model.dart';

abstract class HifzLocalDataSource {
  Future<List<HifzEntryModel>> getAllEntries();
  Future<HifzEntryModel?> getEntry(String id);
  Future<void> saveEntry(HifzEntryModel entry);
  Future<void> deleteEntry(String id);
}

class HifzLocalDataSourceImpl implements HifzLocalDataSource {
  final Box box;

  HifzLocalDataSourceImpl({required this.box});

  @override
  Future<List<HifzEntryModel>> getAllEntries() async {
    try {
      final items = <HifzEntryModel>[];
      for (final e in box.values) {
        if (e is! Map) continue;
        try {
          items.add(HifzEntryModel.fromJson(Map<String, dynamic>.from(e)));
        } catch (err) {
          Logger.warning('Skipping malformed hifz entry: $err', feature: 'HifzLocal');
          continue;
        }
      }
      return items;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<HifzEntryModel?> getEntry(String id) async {
    try {
      final raw = box.get(id);
      if (raw is! Map) return null;
      try {
        return HifzEntryModel.fromJson(Map<String, dynamic>.from(raw));
      } catch (err) {
        Logger.warning('Skipping malformed hifz entry $id: $err', feature: 'HifzLocal');
        return null;
      }
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveEntry(HifzEntryModel entry) async {
    try {
      await box.put(entry.id, entry.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException();
    }
  }
}

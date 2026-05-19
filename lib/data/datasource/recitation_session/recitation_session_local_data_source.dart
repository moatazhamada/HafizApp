import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../model/recitation_session_model.dart';

abstract class RecitationSessionLocalDataSource {
  Future<List<RecitationSessionModel>> getSessions();
  Future<void> addSession(RecitationSessionModel session);
  Future<void> clearAll();
}

class RecitationSessionLocalDataSourceImpl
    implements RecitationSessionLocalDataSource {
  final Box box;

  RecitationSessionLocalDataSourceImpl({required this.box});

  @override
  Future<List<RecitationSessionModel>> getSessions() async {
    try {
      final List<RecitationSessionModel> sessions = [];
      for (final e in box.values) {
        if (e is! Map) continue;
        try {
          sessions.add(
            RecitationSessionModel.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (e) {
          Logger.warning('Skipping malformed recitation session entry: $e', feature: 'RecitationSessionLocal');
          continue;
        }
      }
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> addSession(RecitationSessionModel session) async {
    try {
      await box.put(session.id, session.toJson());
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

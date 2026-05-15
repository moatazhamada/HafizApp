import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../model/reading_goal_model.dart';
import '../../model/reading_session_model.dart';

abstract class KhatmahLocalDataSource {
  Future<DailyReadingLogModel?> getLog(DateTime date);
  Future<void> saveLog(DailyReadingLogModel log);
  Future<List<DailyReadingLogModel>> getRecentLogs(int days);
  Future<Map<String, DailyReadingLogModel>> getLogsBatch(
    DateTime from,
    DateTime to,
  );
  Future<ReadingGoalModel?> getGoal();
  Future<void> saveGoal(ReadingGoalModel goal);
  Future<void> saveOfflineSession(ReadingSessionModel session);
  Future<List<ReadingSessionModel>> getOfflineSessions();
  Future<void> clearOfflineSessions();
}

class KhatmahLocalDataSourceImpl implements KhatmahLocalDataSource {
  final Box logBox;
  final Box goalBox;
  final Box offlineSessionBox;

  KhatmahLocalDataSourceImpl({
    required this.logBox,
    required this.goalBox,
    required this.offlineSessionBox,
  });

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<DailyReadingLogModel?> getLog(DateTime date) async {
    try {
      final raw = logBox.get(_dateKey(date));
      if (raw is! Map) return null;
      return DailyReadingLogModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveLog(DailyReadingLogModel log) async {
    try {
      await logBox.put(_dateKey(log.date), log.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<DailyReadingLogModel>> getRecentLogs(int days) async {
    try {
      final List<DailyReadingLogModel> logs = [];
      final now = DateTime.now();
      for (int i = 0; i < days; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final raw = logBox.get(_dateKey(date));
        if (raw is Map) {
          try {
            logs.add(
              DailyReadingLogModel.fromJson(Map<String, dynamic>.from(raw)),
            );
          } catch (e) {
            Logger.warning('Daily reading log parse failed: $e', feature: 'Khatmah');
          }
        }
      }
      return logs;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<Map<String, DailyReadingLogModel>> getLogsBatch(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final Map<String, DailyReadingLogModel> result = {};
      final allEntries = logBox.toMap();

      // Generate all date keys in the range
      for (int i = 0; i <= to.difference(from).inDays; i++) {
        final date = DateTime(
          from.year,
          from.month,
          from.day,
        ).add(Duration(days: i));
        final key = _dateKey(date);
        final raw = allEntries[key];
        if (raw is Map) {
          try {
            result[key] = DailyReadingLogModel.fromJson(
              Map<String, dynamic>.from(raw),
            );
          } catch (e) {
            Logger.warning('Daily reading log parse failed: $e', feature: 'Khatmah');
          }
        }
      }
      return result;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<ReadingGoalModel?> getGoal() async {
    try {
      final raw = goalBox.get('active_goal');
      if (raw is! Map) return null;
      return ReadingGoalModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveGoal(ReadingGoalModel goal) async {
    try {
      await goalBox.put('active_goal', goal.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveOfflineSession(ReadingSessionModel session) async {
    try {
      await offlineSessionBox.add(session.toJson());
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<ReadingSessionModel>> getOfflineSessions() async {
    try {
      return offlineSessionBox.values
          .map((raw) => ReadingSessionModel.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> clearOfflineSessions() async {
    try {
      await offlineSessionBox.clear();
    } catch (e) {
      throw CacheException();
    }
  }
}

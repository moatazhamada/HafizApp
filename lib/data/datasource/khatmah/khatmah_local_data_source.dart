import 'package:hive/hive.dart';
import '../../../core/errors/exceptions.dart';
import '../../model/reading_goal_model.dart';

abstract class KhatmahLocalDataSource {
  Future<DailyReadingLogModel?> getLog(DateTime date);
  Future<void> saveLog(DailyReadingLogModel log);
  Future<List<DailyReadingLogModel>> getRecentLogs(int days);
  Future<ReadingGoalModel?> getGoal();
  Future<void> saveGoal(ReadingGoalModel goal);
}

class KhatmahLocalDataSourceImpl implements KhatmahLocalDataSource {
  final Box logBox;
  final Box goalBox;

  KhatmahLocalDataSourceImpl({required this.logBox, required this.goalBox});

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
          } catch (_) {}
        }
      }
      return logs;
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
}

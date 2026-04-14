import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/khatmah/khatmah_local_data_source.dart';
import 'package:hafiz_app/data/model/reading_goal_model.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  final KhatmahLocalDataSource localDataSource;

  KhatmahRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, DailyReadingLog?>> getTodayLog() async {
    try {
      final log = await localDataSource.getLog(_today());
      return Right(log);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logReading({int? verses, int? surahs}) async {
    try {
      final existing = await localDataSource.getLog(_today());
      final updated = DailyReadingLogModel(
        date: _today(),
        versesRead: (existing?.versesRead ?? 0) + (verses ?? 0),
        juzRead: existing?.juzRead ?? 0,
        surahsVisited: (existing?.surahsVisited ?? 0) + (surahs ?? 0),
        readingDuration: existing?.readingDuration ?? Duration.zero,
      );
      await localDataSource.saveLog(updated);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReadingGoal?>> getGoal() async {
    try {
      final goal = await localDataSource.getGoal();
      return Right(goal);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setGoal(int dailyVerseTarget) async {
    try {
      final goal = ReadingGoalModel(
        dailyVerseTarget: dailyVerseTarget,
        startDate: DateTime.now(),
        isActive: true,
      );
      await localDataSource.saveGoal(goal);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyReadingLog>>> getRecentLogs(int days) async {
    try {
      final logs = await localDataSource.getRecentLogs(days);
      return Right(logs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getCurrentStreak() async {
    try {
      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final log = await localDataSource.getLog(date);
        if (log != null && log.versesRead > 0) {
          streak++;
        } else if (i > 0) {
          break;
        } else {
          // Today has no reading yet - check if goal allows it
          break;
        }
      }
      return Right(streak);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

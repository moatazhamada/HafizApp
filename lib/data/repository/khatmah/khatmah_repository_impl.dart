import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/khatmah/khatmah_local_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/model/reading_goal_model.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  final KhatmahLocalDataSource localDataSource;
  final QfActivityRemoteDataSource activityRemoteDataSource;
  final QfGoalsRemoteDataSource goalsRemoteDataSource;

  KhatmahRepositoryImpl({
    required this.localDataSource,
    required this.activityRemoteDataSource,
    required this.goalsRemoteDataSource,
  });

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
        syncStatus: SyncStatus.pending,
      );
      await localDataSource.saveLog(updated);

      // Fire-and-forget: report to QF if authenticated
      _reportActivityDay(updated);

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

      // Sync goal to QF
      _syncGoalToQf(dailyVerseTarget);

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
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(const Duration(days: 365));

      // Batch-read all logs for the past year in a single Hive read
      final logs = await localDataSource.getLogsBatch(startDate, today);

      for (int i = 0; i < 365; i++) {
        final date = today.subtract(Duration(days: i));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final log = logs[key];
        if (log != null && log.versesRead > 0) {
          streak++;
        } else if (i > 0) {
          break;
        } else {
          break;
        }
      }
      return Right(streak);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingActivityDays() async {
    try {
      final now = DateTime.now();
      int synced = 0;

      // Check last 30 days for pending logs
      for (int i = 0; i < 30; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final log = await localDataSource.getLog(date);
        if (log != null &&
            log.versesRead > 0 &&
            log.syncStatus != SyncStatus.synced) {
          try {
            await activityRemoteDataSource.postActivityDay(
              type: 'QURAN',
              date:
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              seconds: log.readingDuration.inSeconds > 0
                  ? log.readingDuration.inSeconds
                  : null,
              mushafId: 4, // UthmaniHafs
            );
            // Mark as synced
            final updated = DailyReadingLogModel(
              date: log.date,
              versesRead: log.versesRead,
              juzRead: log.juzRead,
              surahsVisited: log.surahsVisited,
              readingDuration: log.readingDuration,
              syncStatus: SyncStatus.synced,
            );
            await localDataSource.saveLog(updated);
            synced++;
          } catch (e) {
            Logger.warning(
              'Failed to sync activity day ${log.date}: $e',
              feature: 'Khatmah',
            );
            // Mark as failed but continue
            final updated = DailyReadingLogModel(
              date: log.date,
              versesRead: log.versesRead,
              juzRead: log.juzRead,
              surahsVisited: log.surahsVisited,
              readingDuration: log.readingDuration,
              syncStatus: SyncStatus.failed,
            );
            await localDataSource.saveLog(updated);
          }
        }
      }
      return Right(synced);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getReconciledStreak() async {
    try {
      // Get local streak
      final localResult = await getCurrentStreak();
      int localStreak = 0;
      localResult.fold((_) => {}, (s) => localStreak = s);

      // Get cloud streak
      final cloudStreak = await activityRemoteDataSource.getCurrentStreakDays();
      return Right(localStreak > cloudStreak ? localStreak : cloudStreak);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<void> reportReadingSession(int chapterNumber, int verseNumber) async {
    try {
      await goalsRemoteDataSource.postReadingSession(
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
      );
    } catch (e) {
      Logger.warning(
        'Failed to report reading session: $e',
        feature: 'Khatmah',
      );
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Fire-and-forget activity day report to QF.
  Future<void> _reportActivityDay(DailyReadingLog log) async {
    try {
      await activityRemoteDataSource.postActivityDay(
        type: 'QURAN',
        date:
            '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}',
        mushafId: 4, // UthmaniHafs
      );
      // Mark locally as synced
      final synced = DailyReadingLogModel(
        date: log.date,
        versesRead: log.versesRead,
        juzRead: log.juzRead,
        surahsVisited: log.surahsVisited,
        readingDuration: log.readingDuration,
        syncStatus: SyncStatus.synced,
      );
      await localDataSource.saveLog(synced);
    } catch (e) {
      Logger.warning(
        'QF activity day report failed (will retry on next sync): $e',
        feature: 'Khatmah',
      );
    }
  }

  /// Sync the local reading goal to QF Goals API.
  Future<void> _syncGoalToQf(int dailyVerseTarget) async {
    try {
      await goalsRemoteDataSource.createGoal(
        type: 'QURAN_PAGES',
        amount: dailyVerseTarget,
        category: 'QURAN',
        mushafId: 4, // UthmaniHafs
      );
    } catch (e) {
      Logger.warning('Failed to sync goal to QF: $e', feature: 'Khatmah');
    }
  }
}

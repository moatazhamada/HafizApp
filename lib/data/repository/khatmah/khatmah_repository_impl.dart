import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/khatmah/khatmah_local_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_activity/qf_activity_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/model/reading_goal_model.dart';
import 'package:hafiz_app/data/model/reading_session_model.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  final KhatmahLocalDataSource localDataSource;
  final QfActivityRemoteDataSource activityRemoteDataSource;
  final QfGoalsRemoteDataSource goalsRemoteDataSource;
  bool _goalSyncedThisSession = false;
  final Set<String> _hotPathSyncedDays = {};

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
  Future<Either<Failure, void>> logReading({int? verses, int? surahs, int? durationSeconds}) async {
    try {
      final existing = await localDataSource.getLog(_today());
      final updated = DailyReadingLogModel(
        date: _today(),
        versesRead: (existing?.versesRead ?? 0) + (verses ?? 0),
        juzRead: existing?.juzRead ?? 0,
        surahsVisited: (existing?.surahsVisited ?? 0) + (surahs ?? 0),
        readingDuration: (existing?.readingDuration ?? Duration.zero) + Duration(seconds: durationSeconds ?? 0),
        syncStatus: SyncStatus.pending,
      );
      await localDataSource.saveLog(updated);

      // Fire-and-forget: report to QF if authenticated
      unawaited(_reportActivityDay(updated));

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
      unawaited(_syncGoalToQf(dailyVerseTarget));

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
      final utcNow = DateTime.now().toUtc();
      final today = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);
      final startDate = today.subtract(const Duration(days: 365));

      // Batch-read all logs for the past year in a single Hive read
      final logs = await localDataSource.getLogsBatch(startDate, today);

      for (int i = 0; i < 365; i++) {
        final date = today.subtract(Duration(days: i));
        final key = _dateKey(date);
        final log = logs[key];
        // Count only days with actual reading activity
        if (log != null && log.versesRead > 0) {
          streak++;
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

      // Batch-read all 90 days of logs first to avoid N+1 local reads
      final startDate = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 89),
      );
      final endDate = DateTime(now.year, now.month, now.day);
      final allLogs = await localDataSource.getLogsBatch(startDate, endDate);

      final pendingLogs = allLogs.values.where(
        (log) =>
            log.versesRead > 0 &&
            log.syncStatus != SyncStatus.synced &&
            !_hotPathSyncedDays.contains(_dateKey(log.date)),
      );

      // Sync pending logs sequentially to avoid rate limits
      for (final log in pendingLogs) {
        try {
          await activityRemoteDataSource.postActivityDay(
            type: 'QURAN',
            date: _dateKey(log.date),
            seconds: log.readingDuration.inSeconds > 0
                ? log.readingDuration.inSeconds
                : null,
            mushafId: _resolveMushafId(),
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
          // Keep as pending so it retries on next sync
          final updated = DailyReadingLogModel(
            date: log.date,
            versesRead: log.versesRead,
            juzRead: log.juzRead,
            surahsVisited: log.surahsVisited,
            readingDuration: log.readingDuration,
            syncStatus: SyncStatus.pending,
          );
          await localDataSource.saveLog(updated);
        }
      }

      // Also sync granular offline sessions sequentially
      final sessionsWithKeys = await localDataSource.getOfflineSessionsWithKeys();
      if (sessionsWithKeys.isNotEmpty) {
        Logger.info(
          'Attempting to sync ${sessionsWithKeys.length} granular reading sessions',
          feature: 'Khatmah',
        );
        final successfulKeys = <int>[];
        for (final entry in sessionsWithKeys.entries) {
          final key = entry.key;
          final session = entry.value;
          try {
            await goalsRemoteDataSource.postReadingSession(
              chapterNumber: session.surahId,
              verseNumber: session.endVerse,
              mushafId: _resolveMushafId(),
            );
            successfulKeys.add(key);
          } catch (e) {
            Logger.warning(
              'Failed to sync granular session for surah ${session.surahId}: $e',
              feature: 'Khatmah',
            );
          }
        }

        if (successfulKeys.isNotEmpty) {
          await localDataSource.deleteOfflineSessions(successfulKeys);
          Logger.info(
            'Successfully synced ${successfulKeys.length} granular sessions',
            feature: 'Khatmah',
          );
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
  Future<Either<Failure, int>> syncActivityDaysFromCloud() async {
    try {
      final days = await activityRemoteDataSource.getActivityDays();
      int updatedCount = 0;

      for (final dayData in days) {
        final dateStr = dayData['date'] as String?;
        if (dateStr == null) continue;

        try {
          final date = DateTime.parse(dateStr);
          final localDate = DateTime(date.year, date.month, date.day);

          final cloudSeconds = dayData['seconds'] as int? ?? 0;
          // Calculate an estimated verses read from QF if they don't provide verses directly
          // We assume roughly 1 verse per 15 seconds as a rough estimate
          final estimatedVerses = cloudSeconds ~/ 20;

          final localLog = await localDataSource.getLog(localDate);

          if (localLog == null) {
            // Add new log from cloud
            await localDataSource.saveLog(DailyReadingLogModel(
              date: localDate,
              versesRead: estimatedVerses,
              readingDuration: Duration(seconds: cloudSeconds),
              syncStatus: SyncStatus.synced,
            ));
            updatedCount++;
          } else {
            // Merge if cloud has more reading
            final localSeconds = localLog.readingDuration.inSeconds;
            if (cloudSeconds > localSeconds) {
              await localDataSource.saveLog(DailyReadingLogModel(
                date: localDate,
                versesRead: localLog.versesRead > estimatedVerses ? localLog.versesRead : estimatedVerses,
                juzRead: localLog.juzRead,
                surahsVisited: localLog.surahsVisited,
                readingDuration: Duration(seconds: cloudSeconds),
                syncStatus: SyncStatus.synced,
              ));
              updatedCount++;
            }
          }
        } catch (e) {
          Logger.warning('Failed to parse/merge activity day $dateStr: $e', feature: 'Khatmah');
        }
      }

      return Right(updatedCount);
    } catch (e) {
      Logger.error('Failed to sync activity days from cloud: $e', feature: 'Khatmah');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> recordAppOpen() async {
    try {
      final today = _today();
      final existing = await localDataSource.getLog(today);
      if (existing != null) return; // Already recorded today

      await localDataSource.saveLog(
        DailyReadingLogModel(
          date: today,
          versesRead: 0,
          juzRead: 0,
          surahsVisited: 0,
          readingDuration: Duration.zero,
          syncStatus: SyncStatus.pending,
        ),
      );
    } catch (e) {
      Logger.warning('Failed to record app open: $e', feature: 'Khatmah');
    }
  }

  @override
  Future<void> reportReadingSession(ReadingSession session) async {
    try {
      await goalsRemoteDataSource.postReadingSession(
        chapterNumber: session.surahId,
        verseNumber: session.endVerse,
        mushafId: _resolveMushafId(),
      );
    } catch (e) {
      Logger.warning(
        'Failed to report reading session instantly (queuing offline): $e',
        feature: 'Khatmah',
      );
      // Queue offline for later
      try {
        await localDataSource.saveOfflineSession(
          ReadingSessionModel.fromEntity(session),
        );
      } catch (cacheError) {
        Logger.error('Failed to queue offline session: $cacheError', feature: 'Khatmah');
      }
    }
  }

  DateTime _today() {
    // Use UTC midnight for consistent day boundaries across timezones.
    // This prevents streak breakage when the user travels.
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  int _resolveMushafId() {
    if (!PrefUtils.isInitialized) return MushafType.madani.qfMushafId;
    try {
      return MushafType.fromString(PrefUtils().getMushafType()).qfMushafId;
    } catch (_) {
      return MushafType.madani.qfMushafId;
    }
  }

  static String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Fire-and-forget activity day report to QF.
  Future<void> _reportActivityDay(DailyReadingLog log) async {
    try {
      await activityRemoteDataSource.postActivityDay(
        type: 'QURAN',
        date: _dateKey(log.date),
        seconds: log.readingDuration.inSeconds,
        mushafId: _resolveMushafId(),
      );
      // Mark day as synced in hot path to prevent batch re-sync
      _hotPathSyncedDays.add(_dateKey(log.date));
      // Re-read current log to avoid overwriting newer data written concurrently
      final current = await localDataSource.getLog(log.date);
      if (current != null) {
        final synced = DailyReadingLogModel(
          date: log.date,
          versesRead: current.versesRead,
          juzRead: current.juzRead,
          surahsVisited: current.surahsVisited,
          readingDuration: current.readingDuration,
          syncStatus: SyncStatus.synced,
        );
        await localDataSource.saveLog(synced);
      }
    } catch (e) {
      Logger.warning(
        'QF activity day report failed (will retry on next sync): $e',
        feature: 'Khatmah',
      );
    }
  }

  /// Sync the local reading goal to QF Goals API.
  Future<void> _syncGoalToQf(int dailyVerseTarget) async {
    if (_goalSyncedThisSession) return;
    _goalSyncedThisSession = true;
    try {
      await goalsRemoteDataSource.createGoal(
        type: 'QURAN',
        amount: dailyVerseTarget,
        category: 'QURAN',
        mushafId: _resolveMushafId(),
      );
    } catch (e) {
      Logger.warning('Failed to sync goal to QF: $e', feature: 'Khatmah');
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';

abstract class KhatmahRepository {
  Future<Either<Failure, DailyReadingLog?>> getTodayLog();
  Future<Either<Failure, void>> logReading({int? verses, int? surahs});
  Future<Either<Failure, ReadingGoal?>> getGoal();
  Future<Either<Failure, void>> setGoal(int dailyVerseTarget);
  Future<Either<Failure, List<DailyReadingLog>>> getRecentLogs(int days);
  Future<Either<Failure, int>> getCurrentStreak();

  /// Sync pending reading logs to QF Activity Days API.
  /// Returns count of synced logs.
  Future<Either<Failure, int>> syncPendingActivityDays();

  /// Fetch cloud streak from QF and reconcile with local streak (take higher).
  Future<Either<Failure, int>> getReconciledStreak();

  /// Fetch Activity Days from QF and merge them into the local database.
  Future<Either<Failure, int>> syncActivityDaysFromCloud();

  /// Record that the user opened the app today. Creates a daily log
  /// entry if none exists, so the streak counts app opens.
  Future<void> recordAppOpen();

  /// Report a full reading session to QF.
  Future<void> reportReadingSession(ReadingSession session);
}

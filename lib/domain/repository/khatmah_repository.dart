import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';

abstract class KhatmahRepository {
  Future<Either<Failure, DailyReadingLog?>> getTodayLog();
  Future<Either<Failure, void>> logReading({int? verses, int? surahs});
  Future<Either<Failure, ReadingGoal?>> getGoal();
  Future<Either<Failure, void>> setGoal(int dailyVerseTarget);
  Future<Either<Failure, List<DailyReadingLog>>> getRecentLogs(int days);
  Future<Either<Failure, int>> getCurrentStreak();
}

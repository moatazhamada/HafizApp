import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';

abstract class MemorizationRepository {
  Future<Either<Failure, List<MemorizationProgress>>> getAllProgress();
  Future<Either<Failure, MemorizationProgress?>> getProgress(int surahId);
  Future<Either<Failure, void>> saveProgress(MemorizationProgress progress);
  Future<Either<Failure, void>> recordReview(int surahId, double score);

  /// Sync memorization progress to QF Goals API (creates a QURAN_RANGE goal).
  Future<Either<Failure, void>> syncMemorizationGoalToQf();
}

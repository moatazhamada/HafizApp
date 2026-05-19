import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';

abstract class HifzRepository {
  Future<Either<Failure, List<HifzEntry>>> getAllEntries();
  Future<Either<Failure, HifzEntry?>> getEntry(String id);
  Future<Either<Failure, void>> saveEntry(HifzEntry entry);
  Future<Either<Failure, void>> deleteEntry(String id);

  /// Log a review for an entry and compute the next status.
  Future<Either<Failure, HifzEntry>> logReview({
    required String entryId,
    required int score,
    required String scoreLabel,
  });

  /// Migrate old memorization data to the new Hifz format.
  Future<Either<Failure, void>> migrateOldData();
}

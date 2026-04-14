import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/data/datasource/memorization/memorization_local_data_source.dart';
import 'package:hafiz_app/data/model/memorization_progress_model.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class MemorizationRepositoryImpl implements MemorizationRepository {
  final MemorizationLocalDataSource localDataSource;

  MemorizationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<MemorizationProgress>>> getAllProgress() async {
    try {
      final items = await localDataSource.getAllProgress();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProgress?>> getProgress(
    int surahId,
  ) async {
    try {
      final item = await localDataSource.getProgress(surahId);
      return Right(item);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProgress(
    MemorizationProgress progress,
  ) async {
    try {
      final model = MemorizationProgressModel(
        surahId: progress.surahId,
        surahName: progress.surahName,
        status: progress.status,
        easeFactor: progress.easeFactor,
        interval: progress.interval,
        repetition: progress.repetition,
        nextReviewDate: progress.nextReviewDate,
        lastReviewDate: progress.lastReviewDate,
        bestScore: progress.bestScore,
      );
      await localDataSource.saveProgress(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordReview(int surahId, double score) async {
    try {
      final existing = await localDataSource.getProgress(surahId);
      final now = DateTime.now();
      final surahName = QuranIndex.quranSurahs
          .firstWhere(
            (s) => s.id == surahId,
            orElse: () => Surah(surahId, '', ''),
          )
          .nameEnglish;

      int easeFactor;
      int interval;
      int repetition;
      MemorizationStatus status;

      if (existing != null) {
        easeFactor = existing.easeFactor;
        interval = existing.interval;
        repetition = existing.repetition;

        if (score >= 80) {
          if (repetition == 0) {
            interval = 1;
          } else if (repetition == 1) {
            interval = 6;
          } else {
            interval = (interval * easeFactor / 2500).round();
          }
          repetition++;
          easeFactor = _adjustEaseFactor(easeFactor, score);
          status = repetition >= 5
              ? MemorizationStatus.memorized
              : MemorizationStatus.inProgress;
        } else if (score >= 50) {
          repetition = 0;
          interval = 0;
          status = MemorizationStatus.inProgress;
        } else {
          repetition = 0;
          interval = 0;
          easeFactor = _adjustEaseFactor(easeFactor, score);
          status = MemorizationStatus.needsReview;
        }
      } else {
        easeFactor = 2500;
        repetition = 0;
        interval = 0;
        status = score >= 50
            ? MemorizationStatus.inProgress
            : MemorizationStatus.needsReview;
      }

      final nextReview = now.add(Duration(days: interval));
      final updated = MemorizationProgressModel(
        surahId: surahId,
        surahName: surahName,
        status: status,
        easeFactor: easeFactor,
        interval: interval,
        repetition: repetition,
        nextReviewDate: nextReview,
        lastReviewDate: now,
        bestScore: existing != null && existing.bestScore > score
            ? existing.bestScore
            : score,
      );

      await localDataSource.saveProgress(updated);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  int _adjustEaseFactor(int currentEf, double score) {
    final quality = (score / 20).round().clamp(0, 5);
    final newEf = currentEf + (quality - 3) * 100;
    return newEf.clamp(1300, 5000);
  }
}

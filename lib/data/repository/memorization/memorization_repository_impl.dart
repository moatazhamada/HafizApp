import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/srs/srs_algorithm.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/data/datasource/memorization/memorization_local_data_source.dart';
import 'package:hafiz_app/data/datasource/qf_goals/qf_goals_remote_data_source.dart';
import 'package:hafiz_app/data/model/memorization_progress_model.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class MemorizationRepositoryImpl implements MemorizationRepository {
  final MemorizationLocalDataSource localDataSource;
  final QfGoalsRemoteDataSource goalsRemoteDataSource;

  MemorizationRepositoryImpl({
    required this.localDataSource,
    required this.goalsRemoteDataSource,
  });

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
      final surahName = QuranIndex.quranSurahs
          .firstWhere(
            (s) => s.id == surahId,
            orElse: () => Surah(surahId, '', ''),
          )
          .nameEnglish;

      final result = SrsAlgorithm.computeNext(existing: existing, score: score);

      final updated = MemorizationProgressModel(
        surahId: surahId,
        surahName: surahName,
        status: result.status,
        easeFactor: result.easeFactor,
        interval: result.interval,
        repetition: result.repetition,
        nextReviewDate: result.nextReviewDate,
        lastReviewDate: DateTime.now(),
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

  @override
  Future<Either<Failure, void>> syncMemorizationGoalToQf() async {
    try {
      final progress = await localDataSource.getAllProgress();
      final inProgressItems = progress.where(
        (p) =>
            p.status == MemorizationStatus.inProgress ||
            p.status == MemorizationStatus.needsReview,
      );

      // Create a QURAN_RANGE goal for each surah in progress
      for (final item in inProgressItems) {
        try {
          final verseCount = MushafPageIndex.getVerseCount(item.surahId);

          await goalsRemoteDataSource.createGoal(
            type: 'QURAN_RANGE',
            amount: '${item.surahId}:1-${item.surahId}:$verseCount',
            category: 'QURAN',
            mushafId: 4, // UthmaniHafs
          );
        } catch (e) {
          Logger.warning(
            'Failed to sync memorization goal for surah ${item.surahId}: $e',
            feature: 'Memorization',
          );
        }
      }

      Logger.info(
        'Synced ${inProgressItems.length} memorization goals to QF',
        feature: 'Memorization',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

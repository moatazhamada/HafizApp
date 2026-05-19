import 'package:dartz/dartz.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/data/datasource/hifz/hifz_local_data_source.dart';
import 'package:hafiz_app/data/datasource/memorization/memorization_local_data_source.dart';
import 'package:hafiz_app/data/model/hifz_entry_model.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/hifz_repository.dart';
import 'package:uuid/uuid.dart';

class HifzRepositoryImpl implements HifzRepository {
  final HifzLocalDataSource hifzLocal;
  final MemorizationLocalDataSource? oldLocal;

  HifzRepositoryImpl({
    required this.hifzLocal,
    this.oldLocal,
  });

  @override
  Future<Either<Failure, List<HifzEntry>>> getAllEntries() async {
    try {
      final items = await hifzLocal.getAllEntries();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HifzEntry?>> getEntry(String id) async {
    try {
      final item = await hifzLocal.getEntry(id);
      return Right(item);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveEntry(HifzEntry entry) async {
    try {
      await hifzLocal.saveEntry(HifzEntryModel(
        id: entry.id,
        surahId: entry.surahId,
        startVerse: entry.startVerse,
        endVerse: entry.endVerse,
        title: entry.title,
        status: entry.status,
        memorizedDate: entry.memorizedDate,
        lastReviewedDate: entry.lastReviewedDate,
        reviewCount: entry.reviewCount,
        reviewStreak: entry.reviewStreak,
        weakCount: entry.weakCount,
        reviewHistory: entry.reviewHistory,
      ));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String id) async {
    try {
      await hifzLocal.deleteEntry(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HifzEntry>> logReview({
    required String entryId,
    required int score,
    required String scoreLabel,
  }) async {
    try {
      final existing = await hifzLocal.getEntry(entryId);
      if (existing == null) {
        return const Left(CacheFailure('Entry not found'));
      }

      final now = DateTime.now();
      final isSuccess = score >= 80;

      // Build updated history (keep last 50)
      final newLog = ReviewLog(date: now, scoreLabel: scoreLabel, scoreValue: score);
      final history = [newLog, ...existing.reviewHistory].take(50).toList();

      // Compute next status
      final nextStatus = _computeNextStatus(
        existing.status,
        existing.memorizedDate,
        existing.reviewCount + 1,
        existing.reviewStreak,
        existing.weakCount,
        isSuccess,
      );

      final updated = HifzEntryModel(
        id: existing.id,
        surahId: existing.surahId,
        startVerse: existing.startVerse,
        endVerse: existing.endVerse,
        title: existing.title,
        status: nextStatus,
        memorizedDate: existing.memorizedDate,
        lastReviewedDate: now,
        reviewCount: existing.reviewCount + 1,
        reviewStreak: isSuccess ? existing.reviewStreak + 1 : 0,
        weakCount: isSuccess ? 0 : existing.weakCount + 1,
        reviewHistory: history,
      );

      await hifzLocal.saveEntry(updated);
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  HifzStatus _computeNextStatus(
    HifzStatus current,
    DateTime memorizedDate,
    int reviewCount,
    int reviewStreak,
    int weakCount,
    bool isSuccess,
  ) {
    final ageDays = DateTime.now().difference(memorizedDate).inDays;

    if (!isSuccess) {
      // Failed review → weak (or stay weak)
      if (current == HifzStatus.weak && weakCount >= 2) {
        return HifzStatus.newLesson;
      }
      return HifzStatus.weak;
    }

    // Success path
    switch (current) {
      case HifzStatus.newLesson:
        if (reviewStreak + 1 >= 5) return HifzStatus.recent;
        return HifzStatus.newLesson;
      case HifzStatus.recent:
        if (ageDays > 21 && reviewStreak + 1 >= 3) return HifzStatus.solid;
        return HifzStatus.recent;
      case HifzStatus.solid:
        if (ageDays > 60 && reviewCount >= 10) return HifzStatus.mastered;
        return HifzStatus.solid;
      case HifzStatus.mastered:
        return HifzStatus.mastered;
      case HifzStatus.weak:
        if (weakCount == 0) {
          // First success after weakness → back to newLesson
          return HifzStatus.newLesson;
        }
        return HifzStatus.weak;
    }
  }

  @override
  Future<Either<Failure, void>> migrateOldData() async {
    try {
      if (oldLocal == null) return const Right(null);
      if (PrefUtils().getHifzMigrationCompleted()) return const Right(null);

      final oldItems = await oldLocal!.getAllProgress();
      if (oldItems.isEmpty) {
        await PrefUtils().setHifzMigrationCompleted(true);
        return const Right(null);
      }

      for (final old in oldItems) {
        try {
          final verseCount = MushafPageIndex.getVerseCount(old.surahId);
          final status = _mapOldStatus(old.status);
          final entry = HifzEntryModel(
            id: const Uuid().v4(),
            surahId: old.surahId,
            startVerse: 1,
            endVerse: verseCount,
            status: status,
            memorizedDate: old.lastReviewDate.subtract(Duration(days: old.interval)),
            lastReviewedDate: old.lastReviewDate,
            reviewCount: old.repetition,
            reviewStreak: old.repetition,
            weakCount: status == HifzStatus.weak ? 1 : 0,
          );
          await hifzLocal.saveEntry(entry);
        } catch (e) {
          Logger.warning('Failed to migrate old entry for surah ${old.surahId}: $e', feature: 'HifzMigration');
          continue;
        }
      }

      await PrefUtils().setHifzMigrationCompleted(true);
      Logger.info('Migrated ${oldItems.length} old memorization entries to Hifz', feature: 'HifzMigration');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  HifzStatus _mapOldStatus(MemorizationStatus old) {
    switch (old) {
      case MemorizationStatus.memorized:
        return HifzStatus.mastered;
      case MemorizationStatus.inProgress:
        return HifzStatus.solid;
      case MemorizationStatus.needsReview:
        return HifzStatus.weak;
      case MemorizationStatus.notStarted:
        return HifzStatus.newLesson;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/srs/srs_algorithm.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';

MemorizationProgress _makeProgress({
  int surahId = 1,
  String surahName = 'Al-Fatiha',
  int easeFactor = 2500,
  int interval = 1,
  int repetition = 1,
  required DateTime nextReviewDate,
  MemorizationStatus status = MemorizationStatus.inProgress,
}) {
  return MemorizationProgress(
    surahId: surahId,
    surahName: surahName,
    easeFactor: easeFactor,
    interval: interval,
    repetition: repetition,
    nextReviewDate: nextReviewDate,
    lastReviewDate: DateTime.now(),
    status: status,
  );
}

void main() {
  group('SrsAlgorithm', () {
    group('computeNext', () {
      test('creates fresh entry on null existing (high score)', () {
        final result = SrsAlgorithm.computeNext(existing: null, score: 95);
        expect(result.repetition, 1);
        expect(result.interval, 1);
        expect(result.easeFactor, greaterThanOrEqualTo(2500));
        expect(result.status, MemorizationStatus.inProgress);
      });

      test('creates fresh entry with needsReview on low score', () {
        final result = SrsAlgorithm.computeNext(existing: null, score: 20);
        expect(result.repetition, 0);
        expect(result.interval, 0);
        expect(result.status, MemorizationStatus.needsReview);
      });

      test('progresses interval on successful recall', () {
        final existing = _makeProgress(
          easeFactor: 2500,
          interval: 1,
          repetition: 1,
          nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final result = SrsAlgorithm.computeNext(existing: existing, score: 85);
        expect(result.repetition, 2);
        // After rep 1 → interval jumps to 6
        expect(result.interval, 6);
      });

      test('resets on failure (score < 50)', () {
        final existing = _makeProgress(
          easeFactor: 2500,
          interval: 6,
          repetition: 4,
          nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final result = SrsAlgorithm.computeNext(existing: existing, score: 30);
        expect(result.repetition, 0);
        expect(result.interval, 0);
        expect(result.status, MemorizationStatus.needsReview);
      });

      test('interval grows with successive successful reviews', () {
        var progress = _makeProgress(
          easeFactor: 2500,
          interval: 1,
          repetition: 1,
          nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        for (int i = 0; i < 5; i++) {
          final result = SrsAlgorithm.computeNext(
            existing: progress,
            score: 95, // perfect recall increases ease factor
          );
          progress = _makeProgress(
            easeFactor: result.easeFactor,
            interval: result.interval,
            repetition: result.repetition,
            nextReviewDate: result.nextReviewDate,
          );
        }
        // With increasing ease factor, interval should grow beyond 6
        expect(progress.interval, greaterThan(6));
      });

      test('ease factor has a minimum of 1300', () {
        var progress = _makeProgress(
          easeFactor: 1300,
          interval: 1,
          repetition: 1,
          nextReviewDate: DateTime.now(),
        );

        for (int q = 0; q <= 100; q += 20) {
          final result = SrsAlgorithm.computeNext(
            existing: progress,
            score: q.toDouble(),
          );
          expect(result.easeFactor, greaterThanOrEqualTo(1300));
        }
      });

      test('marks as memorized after enough successful repetitions', () {
        var progress = _makeProgress(
          easeFactor: 2500,
          interval: 30,
          repetition: 4,
          nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final result = SrsAlgorithm.computeNext(existing: progress, score: 90);
        expect(result.repetition, 5);
        expect(result.status, MemorizationStatus.memorized);
      });
    });

    group('isDueForReview', () {
      test('returns true when nextReviewDate is in the past', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(SrsAlgorithm.isDueForReview(progress), true);
      });

      test('returns false when nextReviewDate is in the future', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().add(const Duration(days: 2)),
        );
        expect(SrsAlgorithm.isDueForReview(progress), false);
      });

      test('returns false for notStarted status', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 2)),
          status: MemorizationStatus.notStarted,
        );
        expect(SrsAlgorithm.isDueForReview(progress), false);
      });
    });

    group('daysUntilReview', () {
      test('returns positive days for future date', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().add(const Duration(days: 3)),
        );
        final days = SrsAlgorithm.daysUntilReview(progress);
        expect(days, greaterThanOrEqualTo(2));
      });

      test('returns negative days for past date', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        final days = SrsAlgorithm.daysUntilReview(progress);
        expect(days, lessThanOrEqualTo(-1));
      });
    });

    group('urgencyLabel', () {
      test('returns overdue key for past date', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(
          SrsAlgorithm.urgencyLabel(progress),
          'lbl_review_urgency_overdue_days',
        );
      });

      test('returns today key for today', () {
        final progress = _makeProgress(nextReviewDate: DateTime.now());
        expect(SrsAlgorithm.urgencyLabel(progress), 'lbl_review_urgency_today');
      });

      test('returns upcoming key for future date', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().add(const Duration(days: 5)),
        );
        expect(
          SrsAlgorithm.urgencyLabel(progress),
          'lbl_review_urgency_upcoming',
        );
      });

      test('returns tomorrow key for tomorrow', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(
          SrsAlgorithm.urgencyLabel(progress),
          'lbl_review_urgency_tomorrow',
        );
      });

      test('returns yesterday key for yesterday', () {
        final progress = _makeProgress(
          nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(
          SrsAlgorithm.urgencyLabel(progress),
          'lbl_review_urgency_yesterday',
        );
      });
    });

    group('SrsQuality', () {
      test('fromScore maps percentages correctly', () {
        expect(SrsQuality.fromScore(95), SrsQuality.perfectRecall);
        expect(SrsQuality.fromScore(80), SrsQuality.correctHesitant);
        expect(SrsQuality.fromScore(65), SrsQuality.difficultCorrect);
        expect(SrsQuality.fromScore(50), SrsQuality.incorrectHard);
        expect(SrsQuality.fromScore(30), SrsQuality.incorrectEasy);
        expect(SrsQuality.fromScore(10), SrsQuality.completeBlackout);
      });
    });
  });
}

import 'package:hafiz_app/domain/entities/memorization_progress.dart';

/// Quality rating for a review session, mapped to the SM-2 algorithm.
///
/// 0 = complete failure, 5 = perfect recall.
enum SrsQuality {
  completeBlackout(0),
  incorrectEasy(1),
  incorrectHard(2),
  difficultCorrect(3),
  correctHesitant(4),
  perfectRecall(5);

  final int value;
  const SrsQuality(this.value);

  /// Map a percentage score [0–100] to an SM-2 quality rating.
  static SrsQuality fromScore(double percentage) {
    if (percentage >= 95) return SrsQuality.perfectRecall;
    if (percentage >= 80) return SrsQuality.correctHesitant;
    if (percentage >= 65) return SrsQuality.difficultCorrect;
    if (percentage >= 50) return SrsQuality.incorrectHard;
    if (percentage >= 30) return SrsQuality.incorrectEasy;
    return SrsQuality.completeBlackout;
  }
}

/// Result of applying the SM-2 algorithm to a review.
class SrsResult {
  final int easeFactor; // hundredths (2500 = 2.5)
  final int interval; // days
  final int repetition;
  final DateTime nextReviewDate;
  final MemorizationStatus status;

  const SrsResult({
    required this.easeFactor,
    required this.interval,
    required this.repetition,
    required this.nextReviewDate,
    required this.status,
  });
}

/// SM-2 Spaced Repetition Algorithm.
///
/// Implementation based on Piotr Woźniak's SuperMemo 2 algorithm.
/// Ease factor is stored as hundredths (2500 = 2.5) to avoid floating-point
/// precision issues in Hive/JSON serialization.
class SrsAlgorithm {
  static const int _defaultEaseFactor = 2500;
  static const int _minEaseFactor = 1300;
  static const int _maxEaseFactor = 5000;

  /// Minimum repetitions before marking a surah as "memorized".
  static const int memorizedThreshold = 5;

  /// Compute the next review parameters given the current state and review quality.
  ///
  /// If [existing] is null, creates a fresh entry. Otherwise, uses the existing
  /// progress as the starting point.
  static SrsResult computeNext({
    MemorizationProgress? existing,
    required double score,
  }) {
    final quality = SrsQuality.fromScore(score);
    final now = DateTime.now();

    if (existing == null) {
      return _newEntry(quality, score, now);
    }

    return _existingEntry(existing, quality, score, now);
  }

  static SrsResult _newEntry(SrsQuality quality, double score, DateTime now) {
    int interval;
    int repetition;
    MemorizationStatus status;

    switch (quality) {
      case SrsQuality.perfectRecall:
      case SrsQuality.correctHesitant:
        interval = 1;
        repetition = 1;
        status = MemorizationStatus.inProgress;
        break;
      case SrsQuality.difficultCorrect:
        interval = 0; // Review again today
        repetition = 1;
        status = MemorizationStatus.inProgress;
        break;
      case SrsQuality.incorrectHard:
      case SrsQuality.incorrectEasy:
      case SrsQuality.completeBlackout:
        interval = 0;
        repetition = 0;
        status = MemorizationStatus.needsReview;
        break;
    }

    return SrsResult(
      easeFactor: _adjustEaseFactor(_defaultEaseFactor, quality),
      interval: interval,
      repetition: repetition,
      nextReviewDate: now.add(Duration(days: interval)),
      status: status,
    );
  }

  static SrsResult _existingEntry(
    MemorizationProgress existing,
    SrsQuality quality,
    double score,
    DateTime now,
  ) {
    int easeFactor = existing.easeFactor;
    int repetition = existing.repetition;
    int interval = existing.interval;

    if (quality.value >= 3) {
      // Successful recall
      if (repetition == 0) {
        interval = 1;
      } else if (repetition == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor / 2500).round();
      }
      repetition++;
    } else {
      // Failed recall — reset
      repetition = 0;
      interval = 0;
    }

    easeFactor = _adjustEaseFactor(easeFactor, quality);

    MemorizationStatus status;
    if (quality.value < 3) {
      status = MemorizationStatus.needsReview;
    } else if (repetition >= memorizedThreshold && score >= 80) {
      status = MemorizationStatus.memorized;
    } else {
      status = MemorizationStatus.inProgress;
    }

    // Ensure interval is at least 0
    interval = interval.clamp(0, 365 * 2);

    return SrsResult(
      easeFactor: easeFactor,
      interval: interval,
      repetition: repetition,
      nextReviewDate: now.add(Duration(days: interval)),
      status: status,
    );
  }

  /// Adjust ease factor based on recall quality.
  /// EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  /// Stored as hundredths to avoid floating-point issues.
  static int _adjustEaseFactor(int currentEf, SrsQuality quality) {
    final q = quality.value;
    final adjustment =
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)) * 1000; // hundredths
    final newEf = (currentEf + adjustment.round()).clamp(
      _minEaseFactor,
      _maxEaseFactor,
    );
    return newEf;
  }

  /// Check if a given progress entry is due for review today.
  static bool isDueForReview(MemorizationProgress progress) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDate = DateTime(
      progress.nextReviewDate.year,
      progress.nextReviewDate.month,
      progress.nextReviewDate.day,
    );
    return !reviewDate.isAfter(today) &&
        progress.status != MemorizationStatus.notStarted;
  }

  /// Get the number of days until the next review (negative if overdue).
  static int daysUntilReview(MemorizationProgress progress) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDate = DateTime(
      progress.nextReviewDate.year,
      progress.nextReviewDate.month,
      progress.nextReviewDate.day,
    );
    return reviewDate.difference(today).inDays;
  }

  /// Get a localization key for the review urgency label.
  ///
  /// The caller must translate the key via `.tr` and, for the overdue case,
  /// replace the `{days}` placeholder.
  static String urgencyLabel(MemorizationProgress progress) {
    final days = daysUntilReview(progress);
    if (days > 1) return 'lbl_review_urgency_upcoming';
    if (days == 1) return 'lbl_review_urgency_tomorrow';
    if (days == 0) return 'lbl_review_urgency_today';
    if (days == -1) return 'lbl_review_urgency_yesterday';
    return 'lbl_review_urgency_overdue_days';
  }
}

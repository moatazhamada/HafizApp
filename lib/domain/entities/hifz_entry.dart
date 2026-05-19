import 'package:equatable/equatable.dart';

/// Status in the Islamic review cycle.
/// - new: ≤ 7 days old, review daily (Sabaq)
/// - recent: 8–21 days old, review every 2–3 days (Sabaq Qadaim)
/// - solid: > 21 days, review weekly (Dawr)
/// - mastered: > 60 days + 10+ reviews, review every 2 weeks
/// - weak: flagged by user as struggling
enum HifzStatus { newLesson, recent, solid, mastered, weak }

/// A single review log entry.
class ReviewLog extends Equatable {
  final DateTime date;
  final String scoreLabel;
  final int scoreValue;

  const ReviewLog({
    required this.date,
    required this.scoreLabel,
    required this.scoreValue,
  });

  @override
  List<Object?> get props => [date, scoreLabel, scoreValue];
}

/// Represents a memorized portion of a surah (verse range).
class HifzEntry extends Equatable {
  final String id;
  final int surahId;
  final int startVerse;
  final int endVerse;
  final String? title;
  final HifzStatus status;
  final DateTime memorizedDate;
  final DateTime lastReviewedDate;
  final int reviewCount;
  final int reviewStreak;
  final int weakCount;
  final List<ReviewLog> reviewHistory;

  const HifzEntry({
    required this.id,
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    this.title,
    required this.status,
    required this.memorizedDate,
    required this.lastReviewedDate,
    this.reviewCount = 0,
    this.reviewStreak = 0,
    this.weakCount = 0,
    this.reviewHistory = const [],
  });

  HifzEntry copyWith({
    String? id,
    int? surahId,
    int? startVerse,
    int? endVerse,
    String? title,
    HifzStatus? status,
    DateTime? memorizedDate,
    DateTime? lastReviewedDate,
    int? reviewCount,
    int? reviewStreak,
    int? weakCount,
    List<ReviewLog>? reviewHistory,
  }) {
    return HifzEntry(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      title: title ?? this.title,
      status: status ?? this.status,
      memorizedDate: memorizedDate ?? this.memorizedDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      reviewCount: reviewCount ?? this.reviewCount,
      reviewStreak: reviewStreak ?? this.reviewStreak,
      weakCount: weakCount ?? this.weakCount,
      reviewHistory: reviewHistory ?? this.reviewHistory,
    );
  }

  /// Display label for the verse range.
  String get rangeLabel => startVerse == endVerse
      ? '$startVerse'
      : '$startVerse–$endVerse';

  /// Whether this entry is due for review today.
  bool isDueForReview(DateTime today) {
    final daysSinceReview = today.difference(lastReviewedDate).inDays;
    switch (status) {
      case HifzStatus.newLesson:
        return daysSinceReview >= 1;
      case HifzStatus.recent:
        return daysSinceReview >= 2;
      case HifzStatus.solid:
        return daysSinceReview >= 7;
      case HifzStatus.mastered:
        return daysSinceReview >= 14;
      case HifzStatus.weak:
        return daysSinceReview >= 1;
    }
  }

  /// Days until next review (negative if overdue).
  int daysUntilNextReview(DateTime today) {
    final daysSinceReview = today.difference(lastReviewedDate).inDays;
    final interval = switch (status) {
      HifzStatus.newLesson => 1,
      HifzStatus.recent => 2,
      HifzStatus.solid => 7,
      HifzStatus.mastered => 14,
      HifzStatus.weak => 1,
    };
    return interval - daysSinceReview;
  }

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';

enum MemorizationStatus { notStarted, inProgress, memorized, needsReview }

class MemorizationProgress extends Equatable {
  final int surahId;
  final String surahName;
  final MemorizationStatus status;
  final int easeFactor;
  final int interval;
  final int repetition;
  final DateTime nextReviewDate;
  final DateTime lastReviewDate;
  final double bestScore;

  const MemorizationProgress({
    required this.surahId,
    required this.surahName,
    this.status = MemorizationStatus.notStarted,
    this.easeFactor = 2500,
    this.interval = 0,
    this.repetition = 0,
    required this.nextReviewDate,
    required this.lastReviewDate,
    this.bestScore = 0,
  });

  MemorizationProgress copyWith({
    MemorizationStatus? status,
    int? easeFactor,
    int? interval,
    int? repetition,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    double? bestScore,
  }) {
    return MemorizationProgress(
      surahId: surahId,
      surahName: surahName,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetition: repetition ?? this.repetition,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  @override
  List<Object?> get props => [surahId];
}

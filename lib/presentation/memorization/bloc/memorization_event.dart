import 'package:equatable/equatable.dart';

abstract class MemorizationEvent extends Equatable {
  const MemorizationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMemorizationProgress extends MemorizationEvent {}

class RecordReview extends MemorizationEvent {
  final int surahId;
  final double score;

  const RecordReview({required this.surahId, required this.score});

  @override
  List<Object?> get props => [surahId, score];
}

class LoadDueReviews extends MemorizationEvent {}

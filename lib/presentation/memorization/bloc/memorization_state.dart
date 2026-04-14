import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';

abstract class MemorizationState extends Equatable {
  const MemorizationState();

  @override
  List<Object?> get props => [];
}

class MemorizationInitial extends MemorizationState {}

class MemorizationLoading extends MemorizationState {}

class MemorizationLoaded extends MemorizationState {
  final List<MemorizationProgress> allProgress;
  final List<MemorizationProgress> dueReviews;
  final int totalMemorized;
  final int totalInProgress;
  final int totalNotStarted;

  const MemorizationLoaded({
    required this.allProgress,
    required this.dueReviews,
    required this.totalMemorized,
    required this.totalInProgress,
    required this.totalNotStarted,
  });

  @override
  List<Object?> get props => [allProgress, dueReviews];
}

class MemorizationError extends MemorizationState {
  final String message;

  const MemorizationError(this.message);

  @override
  List<Object?> get props => [message];
}

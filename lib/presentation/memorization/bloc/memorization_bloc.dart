import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'memorization_event.dart';
import 'memorization_state.dart';

class MemorizationBloc extends Bloc<MemorizationEvent, MemorizationState> {
  final MemorizationRepository repository;

  MemorizationBloc({required this.repository}) : super(MemorizationInitial()) {
    on<LoadMemorizationProgress>(_onLoadProgress);
    on<RecordReview>(_onRecordReview);
    on<LoadDueReviews>(_onLoadDueReviews);
  }

  Future<void> _onLoadProgress(
    LoadMemorizationProgress event,
    Emitter<MemorizationState> emit,
  ) async {
    emit(MemorizationLoading());
    final result = await repository.getAllProgress();
    result.fold((failure) => emit(MemorizationError(failure.toString())), (
      progress,
    ) {
      final now = DateTime.now();
      final due = progress
          .where(
            (p) =>
                p.status != MemorizationStatus.notStarted &&
                !p.nextReviewDate.isAfter(now),
          )
          .toList();
      final memorized = progress
          .where((p) => p.status == MemorizationStatus.memorized)
          .length;
      final inProgress = progress
          .where(
            (p) =>
                p.status == MemorizationStatus.inProgress ||
                p.status == MemorizationStatus.needsReview,
          )
          .length;
      final notStarted = 114 - progress.length;
      emit(
        MemorizationLoaded(
          allProgress: progress,
          dueReviews: due,
          totalMemorized: memorized,
          totalInProgress: inProgress,
          totalNotStarted: notStarted < 0 ? 0 : notStarted,
        ),
      );
    });
  }

  Future<void> _onRecordReview(
    RecordReview event,
    Emitter<MemorizationState> emit,
  ) async {
    await repository.recordReview(event.surahId, event.score);
    add(LoadMemorizationProgress());
  }

  Future<void> _onLoadDueReviews(
    LoadDueReviews event,
    Emitter<MemorizationState> emit,
  ) async {
    add(LoadMemorizationProgress());
  }
}

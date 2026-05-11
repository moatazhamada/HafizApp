import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/srs/srs_algorithm.dart';
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
    result.fold(
      (failure) => emit(const MemorizationError('msg_operation_failed')),
      (progress) {
        final due = progress.where(SrsAlgorithm.isDueForReview).toList();
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
      },
    );
  }

  Future<void> _onRecordReview(
    RecordReview event,
    Emitter<MemorizationState> emit,
  ) async {
    final result = await repository.recordReview(event.surahId, event.score);
    result.fold(
      (failure) => emit(const MemorizationError('msg_operation_failed')),
      (_) => add(LoadMemorizationProgress()),
    );
  }

  Future<void> _onLoadDueReviews(
    LoadDueReviews event,
    Emitter<MemorizationState> emit,
  ) async {
    add(LoadMemorizationProgress());
  }
}

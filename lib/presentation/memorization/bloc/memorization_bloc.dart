import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/srs/srs_algorithm.dart';
import 'package:hafiz_app/domain/entities/memorization_progress.dart';
import 'package:hafiz_app/domain/repository/memorization_repository.dart';
import 'package:hafiz_app/core/utils/either_extensions.dart';
import 'memorization_event.dart';
import 'memorization_state.dart';

class MemorizationBloc extends Bloc<MemorizationEvent, MemorizationState> {
  final MemorizationRepository repository;

  MemorizationBloc({required this.repository}) : super(MemorizationInitial()) {
    on<LoadMemorizationProgress>(_onLoadProgress);
    on<RecordReview>(_onRecordReview);
    on<LoadDueReviews>(_onLoadDueReviews);
  }

  MemorizationLoaded _computeLoadedState(List<MemorizationProgress> progress) {
    final due = <MemorizationProgress>[];
    int memorized = 0;
    int inProgress = 0;
    for (final p in progress) {
      if (SrsAlgorithm.isDueForReview(p)) due.add(p);
      switch (p.status) {
        case MemorizationStatus.memorized:
          memorized++;
        case MemorizationStatus.inProgress:
        case MemorizationStatus.needsReview:
          inProgress++;
        default:
          break;
      }
    }
    final notStarted = 114 - progress.length;
    return MemorizationLoaded(
      allProgress: progress,
      dueReviews: due,
      totalMemorized: memorized,
      totalInProgress: inProgress,
      totalNotStarted: notStarted < 0 ? 0 : notStarted,
    );
  }

  Future<void> _onLoadProgress(
    LoadMemorizationProgress event,
    Emitter<MemorizationState> emit,
  ) async {
    if (isClosed) return;
    emit(MemorizationLoading());
    final result = await repository.getAllProgress();
    result.fold(
      (failure) => emit(MemorizationError(failure.localizedMessage)),
      (progress) => emit(_computeLoadedState(progress)),
    );
  }

  Future<void> _onRecordReview(
    RecordReview event,
    Emitter<MemorizationState> emit,
  ) async {
    final result = await repository.recordReview(event.surahId, event.score);
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(MemorizationError(failure.localizedMessage));
      },
      (_) {
        if (isClosed) return;
        add(LoadMemorizationProgress());
      },
    );
  }

  Future<void> _onLoadDueReviews(
    LoadDueReviews event,
    Emitter<MemorizationState> emit,
  ) async {
    if (isClosed) return;
    emit(MemorizationLoading());
    final result = await repository.getAllProgress();
    result.fold(
      (failure) => emit(MemorizationError(failure.localizedMessage)),
      (progress) => emit(_computeLoadedState(progress)),
    );
  }
}

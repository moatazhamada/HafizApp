import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../data/model/recitation_error_model.dart';
import '../../../../domain/repository/recitation_error_repository.dart';

part 'recitation_error_event.dart';
part 'recitation_error_state.dart';

class RecitationErrorBloc
    extends Bloc<RecitationErrorEvent, RecitationErrorState> {
  final RecitationErrorRepository repository;

  RecitationErrorBloc({required this.repository})
    : super(RecitationErrorInitial()) {
    on<LoadRecitationErrorsEvent>(_onLoadRecitationErrors);
    on<AddRecitationErrorEvent>(_onAddRecitationError);
    on<RemoveRecitationErrorEvent>(_onRemoveRecitationError);
  }

  Future<void> _onLoadRecitationErrors(
    LoadRecitationErrorsEvent event,
    Emitter<RecitationErrorState> emit,
  ) async {
    emit(RecitationErrorLoading());
    final result = await repository.getRecitationErrors();
    result.fold(
      (failure) => emit(RecitationErrorError(_mapFailureToMessage(failure))),
      (errors) => emit(
        RecitationErrorLoaded(errors, feedbackMessage: event.feedbackMessage),
      ),
    );
  }

  Future<void> _onAddRecitationError(
    AddRecitationErrorEvent event,
    Emitter<RecitationErrorState> emit,
  ) async {
    final result = await repository.addRecitationError(event.error);
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RecitationErrorError(_mapFailureToMessage(failure)));
      },
      (_) {
        if (isClosed) return;
        add(const LoadRecitationErrorsEvent(feedbackMessage: 'msg_marked_error'));
      },
    );
  }

  Future<void> _onRemoveRecitationError(
    RemoveRecitationErrorEvent event,
    Emitter<RecitationErrorState> emit,
  ) async {
    final result = await repository.removeRecitationError(
      event.surahId,
      event.verseId,
    );
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RecitationErrorError(_mapFailureToMessage(failure)));
      },
      (_) {
        if (isClosed) return;
        add(const LoadRecitationErrorsEvent(feedbackMessage: 'msg_error_removed'));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is CacheFailure) {
      return 'msg_cache_error';
    }
    return 'msg_unexpected_error';
  }
}

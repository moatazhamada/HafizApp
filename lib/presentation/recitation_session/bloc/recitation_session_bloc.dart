import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';
import 'package:hafiz_app/core/utils/either_extensions.dart';
import 'recitation_session_event.dart';
import 'recitation_session_state.dart';

class RecitationSessionBloc
    extends Bloc<RecitationSessionEvent, RecitationSessionState> {
  final RecitationSessionRepository repository;

  RecitationSessionBloc({required this.repository})
    : super(RecitationSessionInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<SaveSession>(_onSaveSession);
    on<ClearAllSessions>(_onClearAllSessions);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<RecitationSessionState> emit,
  ) async {
    emit(RecitationSessionLoading());
    final result = await repository.getSessions();
    result.fold(
      (failure) => emit(RecitationSessionError(failure.localizedMessage)),
      (sessions) => emit(RecitationSessionLoaded(sessions)),
    );
  }

  Future<void> _onSaveSession(
    SaveSession event,
    Emitter<RecitationSessionState> emit,
  ) async {
    final result = await repository.addSession(event.session);
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RecitationSessionError(failure.localizedMessage));
      },
      (_) {
        if (isClosed) return;
        final current = state;
        if (current is RecitationSessionLoaded) {
          emit(RecitationSessionLoaded(
            [event.session, ...current.sessions],
          ));
        } else {
          add(LoadSessions());
        }
      },
    );
  }

  Future<void> _onClearAllSessions(
    ClearAllSessions event,
    Emitter<RecitationSessionState> emit,
  ) async {
    final result = await repository.clearAll();
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RecitationSessionError(failure.localizedMessage));
      },
      (_) {
        if (isClosed) return;
        emit(const RecitationSessionLoaded([]));
      },
    );
  }
}

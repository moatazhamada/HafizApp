import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/domain/repository/recitation_session_repository.dart';
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
      (failure) => emit(RecitationSessionError(failure.toString())),
      (sessions) => emit(RecitationSessionLoaded(sessions)),
    );
  }

  Future<void> _onSaveSession(
    SaveSession event,
    Emitter<RecitationSessionState> emit,
  ) async {
    await repository.addSession(event.session);
    add(LoadSessions());
  }

  Future<void> _onClearAllSessions(
    ClearAllSessions event,
    Emitter<RecitationSessionState> emit,
  ) async {
    await repository.clearAll();
    add(LoadSessions());
  }
}

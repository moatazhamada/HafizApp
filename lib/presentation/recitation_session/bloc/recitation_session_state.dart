import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

abstract class RecitationSessionState extends Equatable {
  const RecitationSessionState();

  @override
  List<Object?> get props => [];
}

class RecitationSessionInitial extends RecitationSessionState {}

class RecitationSessionLoading extends RecitationSessionState {}

class RecitationSessionLoaded extends RecitationSessionState {
  final List<RecitationSession> sessions;

  const RecitationSessionLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class RecitationSessionError extends RecitationSessionState {
  final String message;

  const RecitationSessionError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

abstract class RecitationSessionEvent extends Equatable {
  const RecitationSessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends RecitationSessionEvent {}

class SaveSession extends RecitationSessionEvent {
  final RecitationSession session;

  const SaveSession(this.session);

  @override
  List<Object?> get props => [session];
}

class ClearAllSessions extends RecitationSessionEvent {}

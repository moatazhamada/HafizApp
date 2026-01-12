part of 'recitation_error_bloc.dart';

abstract class RecitationErrorEvent extends Equatable {
  const RecitationErrorEvent();

  @override
  List<Object> get props => [];
}

class LoadRecitationErrorsEvent extends RecitationErrorEvent {
  final String? feedbackMessage;

  const LoadRecitationErrorsEvent({this.feedbackMessage});

  @override
  List<Object> get props => [feedbackMessage ?? ''];
}

class AddRecitationErrorEvent extends RecitationErrorEvent {
  final RecitationErrorModel error;

  const AddRecitationErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}

class RemoveRecitationErrorEvent extends RecitationErrorEvent {
  final int surahId;
  final int verseId;

  const RemoveRecitationErrorEvent(this.surahId, this.verseId);

  @override
  List<Object> get props => [surahId, verseId];
}

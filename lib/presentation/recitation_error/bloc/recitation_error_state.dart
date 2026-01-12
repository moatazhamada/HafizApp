part of 'recitation_error_bloc.dart';

abstract class RecitationErrorState extends Equatable {
  const RecitationErrorState();

  @override
  List<Object> get props => [];
}

class RecitationErrorInitial extends RecitationErrorState {}

class RecitationErrorLoading extends RecitationErrorState {}

class RecitationErrorLoaded extends RecitationErrorState {
  final List<RecitationErrorModel> errors;
  final String? feedbackMessage;

  const RecitationErrorLoaded(this.errors, {this.feedbackMessage});

  @override
  List<Object> get props => [errors, feedbackMessage ?? ''];
}

class RecitationErrorError extends RecitationErrorState {
  final String message;

  const RecitationErrorError(this.message);

  @override
  List<Object> get props => [message];
}

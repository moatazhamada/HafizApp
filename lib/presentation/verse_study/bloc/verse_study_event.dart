part of 'verse_study_bloc.dart';

abstract class VerseStudyEvent extends Equatable {
  const VerseStudyEvent();

  @override
  List<Object> get props => [];
}

class LoadVerseStudy extends VerseStudyEvent {
  final String verseKey;

  const LoadVerseStudy(this.verseKey);

  @override
  List<Object> get props => [verseKey];
}

class LoadReflections extends VerseStudyEvent {
  final String verseKey;

  const LoadReflections(this.verseKey);

  @override
  List<Object> get props => [verseKey];
}

class CreateReflection extends VerseStudyEvent {
  final String verseKey;
  final String text;

  const CreateReflection({required this.verseKey, required this.text});

  @override
  List<Object> get props => [verseKey, text];
}

class DeleteReflection extends VerseStudyEvent {
  final String postId;

  const DeleteReflection(this.postId);

  @override
  List<Object> get props => [postId];
}

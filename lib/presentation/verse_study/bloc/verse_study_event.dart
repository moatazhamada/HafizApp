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

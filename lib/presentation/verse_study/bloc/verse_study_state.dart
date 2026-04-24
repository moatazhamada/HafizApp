part of 'verse_study_bloc.dart';

abstract class VerseStudyState extends Equatable {
  const VerseStudyState();

  @override
  List<Object> get props => [];
}

class VerseStudyInitial extends VerseStudyState {}

class VerseStudyLoading extends VerseStudyState {}

class VerseStudyLoaded extends VerseStudyState {
  final String arabicText;
  final String translation;
  final String tafsir;

  const VerseStudyLoaded({
    required this.arabicText,
    required this.translation,
    required this.tafsir,
  });

  @override
  List<Object> get props => [arabicText, translation, tafsir];
}

class VerseStudyError extends VerseStudyState {
  final String message;

  const VerseStudyError(this.message);

  @override
  List<Object> get props => [message];
}

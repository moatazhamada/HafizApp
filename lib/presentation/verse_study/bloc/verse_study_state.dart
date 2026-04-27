part of 'verse_study_bloc.dart';

abstract class VerseStudyState extends Equatable {
  final String? verseKey;

  const VerseStudyState({this.verseKey});

  @override
  List<Object?> get props => [verseKey];
}

class VerseStudyInitial extends VerseStudyState {
  const VerseStudyInitial() : super(verseKey: null);
}

class VerseStudyLoading extends VerseStudyState {
  const VerseStudyLoading({required String verseKey})
    : super(verseKey: verseKey);
}

class VerseStudyLoaded extends VerseStudyState {
  final String arabicText;
  final String translation;
  final String tafsir;

  const VerseStudyLoaded({
    required this.arabicText,
    required this.translation,
    required this.tafsir,
    required String verseKey,
  }) : super(verseKey: verseKey);

  @override
  List<Object?> get props => [arabicText, translation, tafsir, verseKey];
}

class VerseStudyError extends VerseStudyState {
  final String message;

  const VerseStudyError({required this.message, required String verseKey})
    : super(verseKey: verseKey);

  @override
  List<Object?> get props => [message, verseKey];
}

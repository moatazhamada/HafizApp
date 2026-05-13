part of 'verse_study_bloc.dart';

abstract class VerseStudyEvent extends Equatable {
  const VerseStudyEvent();

  @override
  List<Object?> get props => [];
}

class LoadVerseStudy extends VerseStudyEvent {
  final String verseKey;

  const LoadVerseStudy(this.verseKey);

  @override
  List<Object> get props => [verseKey];
}

class LoadVerseStudyWithSources extends VerseStudyEvent {
  final String verseKey;
  final String? tafsirId;
  final String? translationId;

  const LoadVerseStudyWithSources(
    this.verseKey, {
    this.tafsirId,
    this.translationId,
  });

  @override
  List<Object> get props {
    final list = <Object>[verseKey];
    if (tafsirId != null) list.add(tafsirId!);
    if (translationId != null) list.add(translationId!);
    return list;
  }
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

class ChangeTafsirSource extends VerseStudyEvent {
  final String id;
  final String verseKey;

  const ChangeTafsirSource({required this.id, required this.verseKey});

  @override
  List<Object> get props => [id, verseKey];
}

class ChangeTranslationSource extends VerseStudyEvent {
  final String id;
  final String verseKey;

  const ChangeTranslationSource({required this.id, required this.verseKey});

  @override
  List<Object> get props => [id, verseKey];
}

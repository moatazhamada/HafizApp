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
  final String selectedTafsirId;
  final String selectedTranslationId;
  final VerseWordData? words;
  final List<Map<String, dynamic>> reflections;
  final bool reflectionsLoading;

  const VerseStudyLoaded({
    required this.arabicText,
    required this.translation,
    required this.tafsir,
    required String verseKey,
    this.selectedTafsirId = '',
    this.selectedTranslationId = '',
    this.words,
    this.reflections = const [],
    this.reflectionsLoading = false,
  }) : super(verseKey: verseKey);

  VerseStudyLoaded copyWith({
    String? arabicText,
    String? translation,
    String? tafsir,
    String? selectedTafsirId,
    String? selectedTranslationId,
    VerseWordData? words,
    String? verseKey,
    List<Map<String, dynamic>>? reflections,
    bool? reflectionsLoading,
  }) {
    return VerseStudyLoaded(
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      tafsir: tafsir ?? this.tafsir,
      selectedTafsirId: selectedTafsirId ?? this.selectedTafsirId,
      selectedTranslationId: selectedTranslationId ?? this.selectedTranslationId,
      words: words ?? this.words,
      verseKey: verseKey ?? this.verseKey!,
      reflections: reflections ?? this.reflections,
      reflectionsLoading: reflectionsLoading ?? this.reflectionsLoading,
    );
  }

  @override
  List<Object?> get props => [
    arabicText,
    translation,
    tafsir,
    selectedTafsirId,
    selectedTranslationId,
    words,
    verseKey,
    reflections,
    reflectionsLoading,
  ];
}

class VerseStudyError extends VerseStudyState {
  final String message;

  const VerseStudyError({required this.message, required String verseKey})
    : super(verseKey: verseKey);

  @override
  List<Object?> get props => [message, verseKey];
}

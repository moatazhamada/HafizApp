import 'package:equatable/equatable.dart';

/// Represents a single verse in a Surah
class Verse extends Equatable {
  final int chapterNumber;
  final int verseNumber;
  final String arabicText;
  final String? translationText;
  final int audioTimestampMs; // Position in audio file where verse begins

  const Verse({
    required this.chapterNumber,
    required this.verseNumber,
    required this.arabicText,
    this.translationText,
    required this.audioTimestampMs,
  });

  @override
  List<Object?> get props => [
    chapterNumber,
    verseNumber,
    arabicText,
    translationText,
    audioTimestampMs,
  ];

  Verse copyWith({
    int? chapterNumber,
    int? verseNumber,
    String? arabicText,
    String? translationText,
    int? audioTimestampMs,
  }) {
    return Verse(
      chapterNumber: chapterNumber ?? this.chapterNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      translationText: translationText ?? this.translationText,
      audioTimestampMs: audioTimestampMs ?? this.audioTimestampMs,
    );
  }
}

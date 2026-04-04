import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final int chapterId;
  final int verseNumber;
  final String text;
  final String? translation;

  const Verse({
    required this.chapterId,
    required this.verseNumber,
    required this.text,
    this.translation,
  });

  @override
  List<Object?> get props => [chapterId, verseNumber, text, translation];
}

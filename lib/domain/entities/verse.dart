import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final int chapterId;
  final int verseNumber;
  final String text;

  const Verse({
    required this.chapterId,
    required this.verseNumber,
    required this.text,
  });

  @override
  List<Object?> get props => [chapterId, verseNumber, text];
}

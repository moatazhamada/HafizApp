import 'package:equatable/equatable.dart';

class TafsirEntry extends Equatable {
  final int surahNumber;
  final int verseNumber;
  final String text;
  final String sourceName;

  const TafsirEntry({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
    required this.sourceName,
  });

  @override
  List<Object?> get props => [surahNumber, verseNumber, sourceName];
}

import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final int surahId;
  final String surahName;
  final int verseNumber;
  final DateTime createdAt;

  const Bookmark({
    required this.surahId,
    required this.surahName,
    required this.verseNumber,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [surahId, surahName, verseNumber, createdAt];
}

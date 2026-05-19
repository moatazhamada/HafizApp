import 'package:equatable/equatable.dart';

abstract class HifzEvent extends Equatable {
  const HifzEvent();

  @override
  List<Object?> get props => [];
}

class LoadHifzEntries extends HifzEvent {}

class AddHifzEntry extends HifzEvent {
  final int surahId;
  final int startVerse;
  final int endVerse;
  final String? title;

  const AddHifzEntry({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    this.title,
  });

  @override
  List<Object?> get props => [surahId, startVerse, endVerse, title];
}

class LogHifzReview extends HifzEvent {
  final String entryId;
  final int score;
  final String scoreLabel;

  const LogHifzReview({
    required this.entryId,
    required this.score,
    required this.scoreLabel,
  });

  @override
  List<Object?> get props => [entryId, score, scoreLabel];
}

class DeleteHifzEntry extends HifzEvent {
  final String entryId;

  const DeleteHifzEntry(this.entryId);

  @override
  List<Object?> get props => [entryId];
}

class MigrateOldHifzData extends HifzEvent {}

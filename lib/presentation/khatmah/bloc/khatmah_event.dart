import 'package:equatable/equatable.dart';

abstract class KhatmahEvent extends Equatable {
  const KhatmahEvent();

  @override
  List<Object?> get props => [];
}

class LoadKhatmahDashboard extends KhatmahEvent {}

class SetReadingGoal extends KhatmahEvent {
  final int dailyVerseTarget;

  const SetReadingGoal(this.dailyVerseTarget);

  @override
  List<Object?> get props => [dailyVerseTarget];
}

class RecordReading extends KhatmahEvent {
  final int verses;
  final int surahs;
  final int durationSeconds;

  const RecordReading({this.verses = 0, this.surahs = 0, this.durationSeconds = 0});

  @override
  List<Object?> get props => [verses, surahs, durationSeconds];
}

class SyncActivityDays extends KhatmahEvent {}

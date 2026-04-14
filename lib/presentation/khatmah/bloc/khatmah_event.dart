import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';

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

  const RecordReading({this.verses = 0, this.surahs = 0});

  @override
  List<Object?> get props => [verses, surahs];
}

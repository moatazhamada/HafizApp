import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';

abstract class HifzState extends Equatable {
  const HifzState();

  @override
  List<Object?> get props => [];
}

class HifzInitial extends HifzState {}

class HifzLoading extends HifzState {}

class HifzLoaded extends HifzState {
  final List<HifzEntry> entries;
  final List<HifzEntry> dueToday;
  final List<HifzEntry> newLessons;
  final List<HifzEntry> recent;
  final List<HifzEntry> solid;
  final List<HifzEntry> mastered;
  final List<HifzEntry> weak;
  final int totalEntries;
  final int masteredCount;

  const HifzLoaded({
    required this.entries,
    required this.dueToday,
    required this.newLessons,
    required this.recent,
    required this.solid,
    required this.mastered,
    required this.weak,
    required this.totalEntries,
    required this.masteredCount,
  });

  @override
  List<Object?> get props => [entries, dueToday];
}

class HifzError extends HifzState {
  final String message;

  const HifzError(this.message);

  @override
  List<Object?> get props => [message];
}

class HifzActionLoading extends HifzState {}

class HifzActionSuccess extends HifzState {}

class HifzActionError extends HifzState {
  final String message;

  const HifzActionError(this.message);

  @override
  List<Object?> get props => [message];
}

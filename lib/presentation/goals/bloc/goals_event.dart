part of 'goals_bloc.dart';

abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodaysPlan extends GoalsEvent {}

class UpdateGoalEvent extends GoalsEvent {
  final String id;
  final String? type;
  final dynamic amount;
  final String? category;
  final int? duration;

  const UpdateGoalEvent({
    required this.id,
    this.type,
    this.amount,
    this.category,
    this.duration,
  });

  @override
  List<Object?> get props => [id, type, amount, category, duration];
}

class DeleteGoalEvent extends GoalsEvent {
  final String id;
  final String? category;

  const DeleteGoalEvent({
    required this.id,
    this.category,
  });

  @override
  List<Object?> get props => [id, category];
}

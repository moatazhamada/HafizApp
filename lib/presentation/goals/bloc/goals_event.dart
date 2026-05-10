part of 'goals_bloc.dart';

abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodaysPlan extends GoalsEvent {}

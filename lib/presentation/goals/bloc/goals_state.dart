part of 'goals_bloc.dart';

class PlanItem extends Equatable {
  final String id;
  final String type;
  final dynamic amount;
  final String category;
  final String? name;
  final int? progress;
  final int? duration;

  const PlanItem({
    required this.id,
    this.type = '',
    this.amount,
    this.category = '',
    this.name,
    this.progress,
    this.duration,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: (json['id'] ?? json['goal_id'] ?? '').toString(),
      type: json['type']?.toString() ?? '',
      amount: json['amount'],
      category: json['category']?.toString() ?? '',
      name: json['name']?.toString(),
      progress: (json['progress'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [id, type, amount, category, name, progress, duration];
}

abstract class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {}

class GoalsLoading extends GoalsState {}

class GoalsLoaded extends GoalsState {
  final List<PlanItem> items;
  final Map<String, dynamic>? rawData;
  final String? mushafLabelKey;

  const GoalsLoaded({
    required this.items,
    this.rawData,
    this.mushafLabelKey,
  });

  @override
  List<Object?> get props => [items, rawData, mushafLabelKey];
}

class GoalsError extends GoalsState {
  final String message;

  const GoalsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loading state for an action (update/delete) without replacing the list.
class GoalsActionLoading extends GoalsState {}

/// Error state for an action (update/delete) without replacing the list.
class GoalsActionError extends GoalsState {
  final String message;

  const GoalsActionError(this.message);

  @override
  List<Object?> get props => [message];
}

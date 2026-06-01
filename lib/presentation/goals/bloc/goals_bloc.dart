import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/usecase/goals/get_todays_plan.dart';
import 'package:hafiz_app/domain/usecase/goals/update_goal.dart';
import 'package:hafiz_app/domain/usecase/goals/delete_goal.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/utils/either_extensions.dart';
import 'package:hafiz_app/presentation/auth/bloc/qf_auth_bloc.dart';

part 'goals_event.dart';
part 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  final GetTodaysPlan getTodaysPlan;
  final UpdateGoal updateGoal;
  final DeleteGoal deleteGoal;

  GoalsBloc({
    required this.getTodaysPlan,
    required this.updateGoal,
    required this.deleteGoal,
  }) : super(GoalsInitial()) {
    on<LoadTodaysPlan>(_onLoadTodaysPlan);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
  }

  static const List<String> _planTypes = [
    'QURAN_TIME',
    'QURAN_PAGES',
    'QURAN_RANGE',
  ];

  Future<void> _onLoadTodaysPlan(
    LoadTodaysPlan event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());

    final results = await Future.wait(
      _planTypes.map(
        (type) => getTodaysPlan(GetTodaysPlanParams(type: type)),
      ),
    );

    final allItems = <PlanItem>[];
    Map<String, dynamic>? firstData;
    Failure? firstFailure;

    for (final result in results) {
      result.fold(
        (failure) {
          firstFailure ??= failure;
        },
        (data) {
          firstData ??= data;
          allItems.addAll(_parsePlanItems(data));
        },
      );
    }

    if (allItems.isNotEmpty) {
      emit(GoalsLoaded(
        items: allItems,
        rawData: firstData,
        mushafLabelKey: 'lbl_mushaf_uthmani_hafs',
      ));
      return;
    }

    final failure = firstFailure;
    if (failure == null) {
      emit(GoalsLoaded(
        items: const [],
        rawData: firstData,
        mushafLabelKey: 'lbl_mushaf_uthmani_hafs',
      ));
      return;
    }

    Logger.warning(
      'Failed to load today\'s plan: ${failure.errorMessage}',
      feature: 'Goals',
    );

    if (failure is InsufficientScopeFailure) {
      emit(GoalsError(failure.errorMessage));
      _requestReLogin();
      return;
    }

    final msg = failure.errorMessage;
    if (_isAuthError(msg)) {
      emit(const GoalsError('goals_error_auth'));
    } else {
      emit(const GoalsError('msg_operation_failed'));
    }
  }

  Future<void> _onUpdateGoal(
    UpdateGoalEvent event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsActionLoading());
    final result = await updateGoal(UpdateGoalParams(
      id: event.id,
      type: event.type,
      amount: event.amount,
      category: event.category,
      duration: event.duration,
    ));
    result.fold(
      (failure) {
        Logger.warning('Failed to update goal: ${failure.errorMessage}',
            feature: 'Goals');
        if (failure is InsufficientScopeFailure) _requestReLogin();
        emit(GoalsActionError(failure.localizedMessage));
      },
      (_) {
        Logger.info('Updated goal ${event.id}', feature: 'Goals');
        unawaited(sl<AnalyticsService>().logGoalUpdated(event.id));
        // Reload plan after update
        add(LoadTodaysPlan());
      },
    );
  }

  Future<void> _onDeleteGoal(
    DeleteGoalEvent event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsActionLoading());
    final result = await deleteGoal(DeleteGoalParams(
      id: event.id,
      category: event.category,
    ));
    result.fold(
      (failure) {
        Logger.warning('Failed to delete goal: ${failure.errorMessage}',
            feature: 'Goals');
        if (failure is InsufficientScopeFailure) _requestReLogin();
        emit(GoalsActionError(failure.localizedMessage));
      },
      (_) {
        Logger.info('Deleted goal ${event.id}', feature: 'Goals');
        unawaited(sl<AnalyticsService>().logGoalDeleted(event.id));
        // Reload plan after delete
        add(LoadTodaysPlan());
      },
    );
  }

  bool _isAuthError(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('403') ||
        lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden');
  }

  List<PlanItem> _parsePlanItems(Map<String, dynamic>? data) {
    if (data == null) return [];
    final planData = data['plan'];
    if (planData is! List) return [];
    return planData
        .map((item) => PlanItem.fromJson(item as Map<String, dynamic>? ?? {}))
        .toList();
  }

  void _requestReLogin() {
    try {
      sl<QfAuthBloc>().add(QfAuthReLoginRequested());
    } catch (e) {
      Logger.warning('Failed to dispatch re-login: $e', feature: 'Goals');
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/usecase/goals/get_todays_plan.dart';

part 'goals_event.dart';
part 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  final GetTodaysPlan getTodaysPlan;

  GoalsBloc({required this.getTodaysPlan}) : super(GoalsInitial()) {
    on<LoadTodaysPlan>(_onLoadTodaysPlan);
  }

  Future<void> _onLoadTodaysPlan(
    LoadTodaysPlan event,
    Emitter<GoalsState> emit,
  ) async {
    emit(GoalsLoading());
    final result = await getTodaysPlan(
      const GetTodaysPlanParams(type: 'QURAN'),
    );
    result.fold(
      (failure) {
        Logger.warning(
          'Failed to load today\'s plan: ${failure.errorMessage}',
          feature: 'Goals',
        );

        if (failure is InsufficientScopeFailure) {
          emit(GoalsError(failure.errorMessage));
          return;
        }

        // Distinguish auth errors from general failures
        final msg = failure.errorMessage;
        if (_isAuthError(msg)) {
          emit(const GoalsError('goals_error_auth'));
        } else {
          emit(const GoalsError('msg_operation_failed'));
        }
      },
      (data) {
        final items = _parsePlanItems(data);
        emit(GoalsLoaded(items: items, rawData: data));
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
}

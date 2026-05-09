import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final result = await getTodaysPlan(const GetTodaysPlanParams(type: 'QURAN'));
    result.fold(
      (failure) {
        Logger.warning('Failed to load today\'s plan', feature: 'Goals');
        emit(GoalsError(failure.errorMessage));
      },
      (data) {
        final items = _parsePlanItems(data);
        if (items.isEmpty && data == null) {
          emit(const GoalsError('msg_operation_failed'));
        } else {
          emit(GoalsLoaded(
            items: items,
            rawData: data,
          ));
        }
      },
    );
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

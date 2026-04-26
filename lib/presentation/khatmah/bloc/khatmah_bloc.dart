import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'khatmah_event.dart';
import 'khatmah_state.dart';

class KhatmahBloc extends Bloc<KhatmahEvent, KhatmahState> {
  final KhatmahRepository repository;

  KhatmahBloc({required this.repository}) : super(KhatmahInitial()) {
    on<LoadKhatmahDashboard>(_onLoadDashboard);
    on<SetReadingGoal>(_onSetGoal);
    on<RecordReading>(_onRecordReading);
  }

  Future<void> _onLoadDashboard(
    LoadKhatmahDashboard event,
    Emitter<KhatmahState> emit,
  ) async {
    emit(KhatmahLoading());
    try {
      final goalResult = await repository.getGoal();
      final logResult = await repository.getTodayLog();
      final logsResult = await repository.getRecentLogs(30);
      final streakResult = await repository.getCurrentStreak();

      int failCount = 0;

      ReadingGoal? goal;
      goalResult.fold(
        (_) {
          failCount++;
          Logger.warning('Failed to load khatmah goal', feature: 'Khatmah');
        },
        (g) => goal = g,
      );

      DailyReadingLog? todayLog;
      logResult.fold(
        (_) {
          failCount++;
          Logger.warning('Failed to load today log', feature: 'Khatmah');
        },
        (l) => todayLog = l,
      );

      List<DailyReadingLog> recentLogs = [];
      logsResult.fold(
        (_) {
          failCount++;
          Logger.warning('Failed to load recent logs', feature: 'Khatmah');
        },
        (l) => recentLogs = l,
      );

      int streak = 0;
      streakResult.fold(
        (_) {
          failCount++;
          Logger.warning('Failed to load streak', feature: 'Khatmah');
        },
        (s) => streak = s,
      );

      if (failCount == 4) {
        emit(const KhatmahError('msg_operation_failed'));
      } else {
        emit(
          KhatmahDashboardLoaded(
            goal: goal,
            todayLog: todayLog,
            recentLogs: recentLogs,
            streak: streak,
          ),
        );
      }
    } catch (e) {
      emit(const KhatmahError('msg_operation_failed'));
    }
  }

  Future<void> _onSetGoal(
    SetReadingGoal event,
    Emitter<KhatmahState> emit,
  ) async {
    final result = await repository.setGoal(event.dailyVerseTarget);
    result.fold(
      (failure) => emit(const KhatmahError('msg_operation_failed')),
      (_) => add(LoadKhatmahDashboard()),
    );
  }

  Future<void> _onRecordReading(
    RecordReading event,
    Emitter<KhatmahState> emit,
  ) async {
    final result = await repository.logReading(
      verses: event.verses,
      surahs: event.surahs,
    );
    result.fold(
      (failure) => emit(const KhatmahError('msg_operation_failed')),
      (_) => add(LoadKhatmahDashboard()),
    );
  }
}

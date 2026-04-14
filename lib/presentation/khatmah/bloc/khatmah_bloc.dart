import 'package:flutter_bloc/flutter_bloc.dart';
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

      ReadingGoal? goal;
      goalResult.fold((_) {}, (g) => goal = g);

      DailyReadingLog? todayLog;
      logResult.fold((_) {}, (l) => todayLog = l);

      List<DailyReadingLog> recentLogs = [];
      logsResult.fold((_) {}, (l) => recentLogs = l);

      int streak = 0;
      streakResult.fold((_) {}, (s) => streak = s);

      emit(
        KhatmahDashboardLoaded(
          goal: goal,
          todayLog: todayLog,
          recentLogs: recentLogs,
          streak: streak,
        ),
      );
    } catch (e) {
      emit(KhatmahError(e.toString()));
    }
  }

  Future<void> _onSetGoal(
    SetReadingGoal event,
    Emitter<KhatmahState> emit,
  ) async {
    await repository.setGoal(event.dailyVerseTarget);
    add(LoadKhatmahDashboard());
  }

  Future<void> _onRecordReading(
    RecordReading event,
    Emitter<KhatmahState> emit,
  ) async {
    await repository.logReading(verses: event.verses, surahs: event.surahs);
    add(LoadKhatmahDashboard());
  }
}

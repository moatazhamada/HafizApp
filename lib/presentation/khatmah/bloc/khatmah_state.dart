import 'package:equatable/equatable.dart';
import 'package:hafiz_app/domain/entities/reading_goal.dart';

abstract class KhatmahState extends Equatable {
  const KhatmahState();

  @override
  List<Object?> get props => [];
}

class KhatmahInitial extends KhatmahState {}

class KhatmahLoading extends KhatmahState {}

class KhatmahDashboardLoaded extends KhatmahState {
  final ReadingGoal? goal;
  final DailyReadingLog? todayLog;
  final List<DailyReadingLog> recentLogs;
  final int streak;

  const KhatmahDashboardLoaded({
    this.goal,
    this.todayLog,
    this.recentLogs = const [],
    this.streak = 0,
  });

  double get todayProgress {
    if (goal == null || goal!.dailyVerseTarget == 0) return 0;
    final read = todayLog?.versesRead ?? 0;
    return (read / goal!.dailyVerseTarget).clamp(0.0, 1.0);
  }

  int get versesReadToday => todayLog?.versesRead ?? 0;

  @override
  List<Object?> get props => [goal, todayLog, recentLogs, streak];
}

class KhatmahError extends KhatmahState {
  final String message;

  const KhatmahError(this.message);

  @override
  List<Object?> get props => [message];
}

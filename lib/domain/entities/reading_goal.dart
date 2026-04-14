import 'package:equatable/equatable.dart';

class DailyReadingLog extends Equatable {
  final DateTime date;
  final int versesRead;
  final int juzRead;
  final int surahsVisited;
  final Duration readingDuration;

  const DailyReadingLog({
    required this.date,
    this.versesRead = 0,
    this.juzRead = 0,
    this.surahsVisited = 0,
    this.readingDuration = Duration.zero,
  });

  DailyReadingLog copyWith({
    int? versesRead,
    int? juzRead,
    int? surahsVisited,
    Duration? readingDuration,
  }) {
    return DailyReadingLog(
      date: date,
      versesRead: versesRead ?? this.versesRead,
      juzRead: juzRead ?? this.juzRead,
      surahsVisited: surahsVisited ?? this.surahsVisited,
      readingDuration: readingDuration ?? this.readingDuration,
    );
  }

  @override
  List<Object?> get props => [date];
}

class ReadingGoal extends Equatable {
  final int dailyVerseTarget;
  final DateTime startDate;
  final bool isActive;

  const ReadingGoal({
    required this.dailyVerseTarget,
    required this.startDate,
    this.isActive = true,
  });

  ReadingGoal copyWith({
    int? dailyVerseTarget,
    DateTime? startDate,
    bool? isActive,
  }) {
    return ReadingGoal(
      dailyVerseTarget: dailyVerseTarget ?? this.dailyVerseTarget,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [dailyVerseTarget, startDate];
}

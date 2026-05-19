import '../../domain/entities/reading_goal.dart';

class DailyReadingLogModel extends DailyReadingLog {
  const DailyReadingLogModel({
    required super.date,
    super.versesRead,
    super.juzRead,
    super.surahsVisited,
    super.readingDuration,
    super.syncStatus,
  });

  String get _dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    return {
      'dataVersion': 1,
      'date': _dateKey,
      'versesRead': versesRead,
      'juzRead': juzRead,
      'surahsVisited': surahsVisited,
      'readingDurationMs': readingDuration.inMilliseconds,
      'syncStatus': syncStatus.index,
    };
  }

  factory DailyReadingLogModel.fromJson(Map<dynamic, dynamic> json) {
    return DailyReadingLogModel(
      date: DateTime.parse(json['date'] as String),
      versesRead: (json['versesRead'] as num?)?.toInt() ?? 0,
      juzRead: (json['juzRead'] as num?)?.toInt() ?? 0,
      surahsVisited: (json['surahsVisited'] as num?)?.toInt() ?? 0,
      readingDuration: Duration(
        milliseconds: (json['readingDurationMs'] as num?)?.toInt() ?? 0,
      ),
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.values[(json['syncStatus'] as num).toInt()]
          : SyncStatus.pending,
    );
  }
}

class ReadingGoalModel extends ReadingGoal {
  const ReadingGoalModel({
    required super.dailyVerseTarget,
    required super.startDate,
    super.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataVersion': 1,
      'dailyVerseTarget': dailyVerseTarget,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ReadingGoalModel.fromJson(Map<dynamic, dynamic> json) {
    return ReadingGoalModel(
      dailyVerseTarget: (json['dailyVerseTarget'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

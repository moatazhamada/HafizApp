import 'package:equatable/equatable.dart';

/// Represents a tajweed rule category where the user has made mistakes.
class TajweedWeakness extends Equatable {
  final String ruleName;
  final int errorCount;
  final double accuracy; // 0.0–1.0
  final List<String> exampleVerseKeys;

  const TajweedWeakness({
    required this.ruleName,
    required this.errorCount,
    required this.accuracy,
    this.exampleVerseKeys = const [],
  });

  @override
  List<Object?> get props => [ruleName];
}

/// Overall tajweed progress summary.
class TajweedProgress extends Equatable {
  final double overallAccuracy;
  final int totalSessions;
  final int totalMistakes;
  final List<TajweedWeakness> weakAreas;
  final DateTime? lastSessionDate;

  const TajweedProgress({
    this.overallAccuracy = 0,
    this.totalSessions = 0,
    this.totalMistakes = 0,
    this.weakAreas = const [],
    this.lastSessionDate,
  });

  bool get hasData => totalSessions > 0;

  @override
  List<Object?> get props => [overallAccuracy, totalSessions];
}

/// A practice recommendation for improving a specific tajweed rule.
class TajweedPracticeItem extends Equatable {
  final String ruleName;
  final String verseKey;
  final String reason;

  const TajweedPracticeItem({
    required this.ruleName,
    required this.verseKey,
    required this.reason,
  });

  @override
  List<Object?> get props => [verseKey, ruleName];
}

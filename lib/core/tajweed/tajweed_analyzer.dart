import 'package:hafiz_app/core/tajweed/tajweed_models.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

/// Analyzes tajweed mistakes across recitation sessions to identify weak areas
/// and generate personalized practice plans.
class TajweedAnalyzer {
  /// Analyze the full recitation history and produce a progress summary.
  ///
  /// [sessions] — all past recitation sessions with scores.
  /// [errors] — all marked practice verses with optional tajweed metadata.
  /// [tajweedMistakeLog] — optional map of session ID → list of tajweed rule names.
  static TajweedProgress analyze({
    required List<RecitationSession> sessions,
    required List<RecitationErrorModel> errors,
    Map<String, List<String>> tajweedMistakeLog = const {},
  }) {
    if (sessions.isEmpty && errors.isEmpty) {
      return const TajweedProgress();
    }

    // Aggregate overall accuracy from sessions
    double totalScore = 0;
    int totalMistakes = errors.length;
    DateTime? lastSessionDate;

    for (final session in sessions) {
      totalScore += session.score;
      if (lastSessionDate == null ||
          session.createdAt.isAfter(lastSessionDate)) {
        lastSessionDate = session.createdAt;
      }
    }

    final overallAccuracy =
        sessions.isNotEmpty ? totalScore / sessions.length / 100.0 : 0.0;

    // Aggregate tajweed rule mistakes from the log
    final Map<String, int> ruleCounts = {};
    final Map<String, List<String>> ruleVerseExamples = {};

    for (final entry in tajweedMistakeLog.entries) {
      for (final rule in entry.value) {
        ruleCounts[rule] = (ruleCounts[rule] ?? 0) + 1;
        // We don't have verse keys in the log, so skip examples
      }
    }

    // If no detailed tajweed log, use error count as generic weaknesses
    if (ruleCounts.isEmpty && errors.isNotEmpty) {
      ruleCounts['general'] = errors.length;
      for (final error in errors.take(5)) {
        ruleVerseExamples
            .putIfAbsent('general', () => [])
            .add('${error.surahId}:${error.verseId}');
      }
    }

    // Build weakness list sorted by error count (worst first)
    final totalRuleErrors =
        ruleCounts.values.fold(0, (sum, count) => sum + count);

    final weakAreas = ruleCounts.entries.map((entry) {
      final accuracy = totalRuleErrors > 0
          ? 1.0 - (entry.value / totalRuleErrors)
          : 1.0;
      return TajweedWeakness(
        ruleName: entry.key,
        errorCount: entry.value,
        accuracy: accuracy.clamp(0.0, 1.0),
        exampleVerseKeys: ruleVerseExamples[entry.key] ?? [],
      );
    }).toList()
      ..sort((a, b) => b.errorCount.compareTo(a.errorCount));

    return TajweedProgress(
      overallAccuracy: overallAccuracy.clamp(0.0, 1.0),
      totalSessions: sessions.length,
      totalMistakes: totalMistakes,
      weakAreas: weakAreas,
      lastSessionDate: lastSessionDate,
    );
  }

  /// Generate a practice plan based on the identified weak areas.
  static List<TajweedPracticeItem> generatePracticePlan(
    TajweedProgress progress,
  ) {
    final items = <TajweedPracticeItem>[];

    for (final weakness in progress.weakAreas) {
      for (final verseKey in weakness.exampleVerseKeys.take(3)) {
        items.add(TajweedPracticeItem(
          ruleName: weakness.ruleName,
          verseKey: verseKey,
          reason: '${weakness.errorCount} mistakes',
        ));
      }
    }

    return items;
  }
}

import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';

/// Automatically adjusts QRC hafz/tajweed levels based on recitation
/// session performance history.
class AdaptiveQrc {
  /// Minimum number of sessions required before auto-adjusting.
  static const int minSessions = 3;

  /// Score thresholds for level changes.
  static const double _upgradeThreshold = 0.90; // 90%+ → increase level
  static const double _downgradeThreshold = 0.50; // <50% → decrease level

  /// Analyzes recent sessions and adjusts QRC levels if adaptive mode is on.
  ///
  /// Returns `true` if levels were changed.
  static bool evaluateAndAdjust(List<RecitationSession> recentSessions) {
    if (!PrefUtils().isAdaptiveQrc()) return false;
    if (recentSessions.length < minSessions) return false;

    // Take the most recent sessions (up to 10)
    final recent = recentSessions.take(10).toList();
    final avgScore =
        recent.map((s) => s.score / 100.0).reduce((a, b) => a + b) /
        recent.length;

    bool changed = false;
    final currentHafz = PrefUtils().getQrcHafzLevel();
    final currentTajweed = PrefUtils().getQrcTajweedLevel();

    // Adjust hafz level (1-3)
    if (avgScore >= _upgradeThreshold && currentHafz < 3) {
      PrefUtils().setQrcHafzLevel(currentHafz + 1);
      changed = true;
    } else if (avgScore < _downgradeThreshold && currentHafz > 1) {
      PrefUtils().setQrcHafzLevel(currentHafz - 1);
      changed = true;
    }

    // Adjust tajweed level (1-5) — only on strong signal
    if (avgScore >= 0.95 && currentTajweed < 5) {
      PrefUtils().setQrcTajweedLevel(currentTajweed + 1);
      changed = true;
    } else if (avgScore < 0.40 && currentTajweed > 1) {
      PrefUtils().setQrcTajweedLevel(currentTajweed - 1);
      changed = true;
    }

    return changed;
  }

  /// Returns a summary of current adaptive state for display.
  static AdaptiveQrcStatus getStatus(List<RecitationSession> recentSessions) {
    final hafz = PrefUtils().getQrcHafzLevel();
    final tajweed = PrefUtils().getQrcTajweedLevel();
    final isAdaptive = PrefUtils().isAdaptiveQrc();
    final sessionCount = recentSessions.length;

    double avgScore = 0;
    if (sessionCount > 0) {
      avgScore =
          recentSessions
              .take(10)
              .map((s) => s.score / 100.0)
              .reduce((a, b) => a + b) /
          recentSessions.take(10).length;
    }

    return AdaptiveQrcStatus(
      hafzLevel: hafz,
      tajweedLevel: tajweed,
      isAdaptive: isAdaptive,
      averageScore: avgScore,
      sessionCount: sessionCount,
      ready: sessionCount >= minSessions,
    );
  }
}

class AdaptiveQrcStatus {
  final int hafzLevel;
  final int tajweedLevel;
  final bool isAdaptive;
  final double averageScore;
  final int sessionCount;
  final bool ready;

  const AdaptiveQrcStatus({
    required this.hafzLevel,
    required this.tajweedLevel,
    required this.isAdaptive,
    required this.averageScore,
    required this.sessionCount,
    required this.ready,
  });
}

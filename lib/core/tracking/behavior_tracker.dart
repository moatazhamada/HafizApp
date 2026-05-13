import 'dart:convert';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';

/// Tracks lightweight user behavior sessions to suggest the optimal surface.
/// Stores at most 7 sessions locally in SharedPreferences.
class BehaviorTracker {
  static const String _sessionsKey = 'behavior_sessions_v1';
  static const String _sessionCountKey = 'behavior_session_count';
  static const String _suggestionDismissedKey = 'surface_suggestion_dismissed';
  static const int _maxSessions = 7;

  /// Records a session with the primary action type.
  static Future<void> recordSession(String action) async {
    final sessions = _getSessions();
    sessions.add({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only the last N sessions
    while (sessions.length > _maxSessions) {
      sessions.removeAt(0);
    }

    await PrefUtils().setString(_sessionsKey, jsonEncode(sessions));
    await PrefUtils().setInt(_sessionCountKey, sessions.length);
  }

  /// Returns the number of recorded sessions.
  static int getSessionCount() {
    return PrefUtils().getInt(_sessionCountKey) ?? 0;
  }

  /// Returns true if we have enough sessions to suggest a surface.
  static bool hasEnoughData() => getSessionCount() >= _maxSessions;

  /// Analyzes sessions and returns the dominant action type.
  static String? detectDominantAction() {
    final sessions = _getSessions();
    if (sessions.length < _maxSessions) return null;

    final counts = <String, int>{};
    for (final session in sessions) {
      final action = session['action'] as String? ?? 'read';
      counts[action] = (counts[action] ?? 0) + 1;
    }

    String? dominant;
    int maxCount = 0;
    counts.forEach((action, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = action;
      }
    });

    return dominant;
  }

  /// Returns a suggested surface based on dominant action, or null if no suggestion.
  static String? suggestSurfaceType() {
    final dominant = detectDominantAction();
    return switch (dominant) {
      'memorize' || 'practice' || 'bookmark' => 'student',
      'search' || 'explore' => 'seeker',
      _ => null,
    };
  }

  /// Marks the suggestion as dismissed so it never shows again.
  static Future<void> dismissSuggestion() async {
    await PrefUtils().setBool(_suggestionDismissedKey, true);
  }

  static bool isSuggestionDismissed() {
    return PrefUtils().getBool(_suggestionDismissedKey) ?? false;
  }

  /// Resets all tracking data (for testing or reset).
  static Future<void> reset() async {
    await PrefUtils().remove(_sessionsKey);
    await PrefUtils().remove(_sessionCountKey);
    await PrefUtils().remove(_suggestionDismissedKey);
  }

  static List<Map<String, dynamic>> _getSessions() {
    try {
      final raw = PrefUtils().getString(_sessionsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.warning('Failed to decode behavior sessions: $e', feature: 'BehaviorTracker');
      return [];
    }
  }
}

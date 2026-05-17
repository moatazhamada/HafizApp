import '../../domain/entities/reading_session.dart';

class ReadingSessionTracker {
  DateTime? _batchStartTime;
  DateTime? _currentStartTime;
  DateTime? _pauseTime;
  int _totalPausedSeconds = 0;

  final List<ReadingSession> _completedSessions = [];

  int? _currentSurahId;
  int? _currentStartVerse;
  int? _currentEndVerse;

  int? get surahId => _currentSurahId;

  void startSession({required int surahId, int startVerse = 1}) {
    if (_currentSurahId == surahId) return;

    _finalizeCurrent(DateTime.now());

    _batchStartTime ??= DateTime.now();
    _currentStartTime = DateTime.now();
    _currentSurahId = surahId;
    _currentStartVerse = startVerse;
    _currentEndVerse = startVerse;
    _pauseTime = null;
    _totalPausedSeconds = 0;
  }

  void updateProgress(int verseNumber) {
    if (_currentEndVerse == null || verseNumber > _currentEndVerse!) {
      _currentEndVerse = verseNumber;
    }
  }

  /// Pause the session timer (e.g., when app goes inactive/background).
  /// Safe to call multiple times — only the first pause is recorded.
  void pause() {
    _pauseTime ??= DateTime.now();
  }

  /// Resume the session timer (e.g., when app returns to foreground).
  /// Accumulates paused duration so it can be subtracted from total time.
  void resume() {
    if (_pauseTime != null) {
      _totalPausedSeconds += DateTime.now().difference(_pauseTime!).inSeconds;
      _pauseTime = null;
    }
  }

  void _finalizeCurrent(DateTime endTime) {
    if (_currentSurahId != null && _currentStartTime != null) {
      var duration = endTime.difference(_currentStartTime!);

      // Subtract any accumulated background/paused time.
      final paused = Duration(seconds: _totalPausedSeconds);
      if (duration > paused) {
        duration -= paused;
      } else {
        duration = Duration.zero;
      }

      _completedSessions.add(ReadingSession(
        surahId: _currentSurahId!,
        startVerse: _currentStartVerse ?? 1,
        endVerse: _currentEndVerse ?? _currentStartVerse ?? 1,
        durationSeconds: duration.inSeconds,
        readAt: _currentStartTime!,
      ));
    }
    _currentSurahId = null;
    _pauseTime = null;
    _totalPausedSeconds = 0;
  }

  List<ReadingSession> endSession() {
    _finalizeCurrent(DateTime.now());

    final validSessions = <ReadingSession>[];

    if (_batchStartTime != null) {
      final totalBatchDuration = DateTime.now().difference(_batchStartTime!).inSeconds;

      for (var session in _completedSessions) {
        // False Positive Prevention:
        // If the entire continuous batch of reading lasted less than 10 seconds,
        // it is likely accidental or just a quick glance. We discard it.
        if (totalBatchDuration < 10) {
          continue;
        }

        validSessions.add(session);
      }
    }

    _completedSessions.clear();
    _batchStartTime = null;
    _currentStartTime = null;
    _pauseTime = null;
    _totalPausedSeconds = 0;

    return validSessions;
  }
}

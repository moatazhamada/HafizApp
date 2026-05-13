import '../../domain/entities/reading_session.dart';

class ReadingSessionTracker {
  DateTime? _startTime;
  int? _surahId;
  int? _startVerse;
  int? _endVerse;

  int? get surahId => _surahId;

  void startSession({required int surahId, int startVerse = 1}) {
    _startTime = DateTime.now();
    _surahId = surahId;
    _startVerse = startVerse;
    _endVerse = startVerse;
  }

  void updateProgress(int verseNumber) {
    if (_endVerse == null || verseNumber > _endVerse!) {
      _endVerse = verseNumber;
    }
  }

  ReadingSession? endSession() {
    if (_startTime == null || _surahId == null) return null;
    final duration = DateTime.now().difference(_startTime!);
    // Only log if user spent at least 10 seconds reading
    if (duration.inSeconds < 10) return null;
    final session = ReadingSession(
      surahId: _surahId!,
      startVerse: _startVerse ?? 1,
      endVerse: _endVerse ?? _startVerse ?? 1,
      durationSeconds: duration.inSeconds,
      readAt: _startTime!,
    );
    _reset();
    return session;
  }

  void _reset() {
    _startTime = null;
    _surahId = null;
    _startVerse = null;
    _endVerse = null;
  }
}

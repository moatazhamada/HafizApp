import '../../domain/entities/reading_session.dart';

class ReadingSessionTracker {
  DateTime? _batchStartTime;
  DateTime? _currentStartTime;
  
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
  }

  void updateProgress(int verseNumber) {
    if (_currentEndVerse == null || verseNumber > _currentEndVerse!) {
      _currentEndVerse = verseNumber;
    }
  }

  void _finalizeCurrent(DateTime endTime) {
    if (_currentSurahId != null && _currentStartTime != null) {
      final duration = endTime.difference(_currentStartTime!);
      
      _completedSessions.add(ReadingSession(
        surahId: _currentSurahId!,
        startVerse: _currentStartVerse ?? 1,
        endVerse: _currentEndVerse ?? _currentStartVerse ?? 1,
        durationSeconds: duration.inSeconds,
        readAt: _currentStartTime!,
      ));
    }
    _currentSurahId = null;
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
    
    return validSessions;
  }
}

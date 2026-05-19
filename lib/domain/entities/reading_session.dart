class ReadingSession {
  final int surahId;
  final int startVerse;
  final int endVerse;
  final int durationSeconds;
  final DateTime readAt;

  const ReadingSession({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    required this.durationSeconds,
    required this.readAt,
  });
}

import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/reading_session.dart';

class ReadingSessionModel extends ReadingSession {
  const ReadingSessionModel({
    required super.surahId,
    required super.startVerse,
    required super.endVerse,
    required super.durationSeconds,
    required super.readAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'durationSeconds': durationSeconds,
      'readAt': readAt.toIso8601String(),
    };
  }

  factory ReadingSessionModel.fromJson(Map<dynamic, dynamic> json) {
    return ReadingSessionModel(
      surahId: (json['surahId'] as num?)?.toInt() ?? 0,
      startVerse: (json['startVerse'] as num?)?.toInt() ?? 0,
      endVerse: (json['endVerse'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      readAt: parseDateTime(json['readAt']) ?? DateTime.now(),
    );
  }

  factory ReadingSessionModel.fromEntity(ReadingSession entity) {
    return ReadingSessionModel(
      surahId: entity.surahId,
      startVerse: entity.startVerse,
      endVerse: entity.endVerse,
      durationSeconds: entity.durationSeconds,
      readAt: entity.readAt,
    );
  }
}

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/memorization_progress.dart';

class MemorizationProgressModel extends MemorizationProgress {
  const MemorizationProgressModel({
    required super.surahId,
    required super.surahName,
    super.status,
    super.easeFactor,
    super.interval,
    super.repetition,
    required super.nextReviewDate,
    required super.lastReviewDate,
    super.bestScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataVersion': 1,
      'surahId': surahId,
      'surahName': surahName,
      'status': status.index,
      'easeFactor': easeFactor,
      'interval': interval,
      'repetition': repetition,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewDate': lastReviewDate.toIso8601String(),
      'bestScore': bestScore,
    };
  }

  factory MemorizationProgressModel.fromJson(Map<dynamic, dynamic> json) {
    return MemorizationProgressModel(
      surahId: (json['surahId'] as num).toInt(),
      surahName: json['surahName'] as String,
      status: _parseStatus(json['status']),
      easeFactor: (json['easeFactor'] as num?)?.toInt() ?? 2500,
      interval: (json['interval'] as num?)?.toInt() ?? 0,
      repetition: (json['repetition'] as num?)?.toInt() ?? 0,
      nextReviewDate: parseDateTime(json['nextReviewDate']) ?? DateTime.now(),
      lastReviewDate: parseDateTime(json['lastReviewDate']) ?? DateTime.now(),
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0,
    );
  }

  static MemorizationStatus _parseStatus(dynamic raw) {
    final index = (raw as num?)?.toInt() ?? 0;
    if (index >= 0 && index < MemorizationStatus.values.length) {
      return MemorizationStatus.values[index];
    }
    Logger.warning('Out-of-range MemorizationStatus index: $index, defaulting to notStarted', feature: 'MemorizationLocal');
    return MemorizationStatus.notStarted;
  }
}

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/hifz_entry.dart';

class HifzEntryModel extends HifzEntry {
  const HifzEntryModel({
    required super.id,
    required super.surahId,
    required super.startVerse,
    required super.endVerse,
    super.title,
    required super.status,
    required super.memorizedDate,
    required super.lastReviewedDate,
    super.reviewCount,
    super.reviewStreak,
    super.weakCount,
    super.reviewHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataVersion': 1,
      'id': id,
      'surahId': surahId,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'title': title,
      'status': status.index,
      'memorizedDate': memorizedDate.toIso8601String(),
      'lastReviewedDate': lastReviewedDate.toIso8601String(),
      'reviewCount': reviewCount,
      'reviewStreak': reviewStreak,
      'weakCount': weakCount,
      'reviewHistory': reviewHistory.map((r) => {
        'date': r.date.toIso8601String(),
        'scoreLabel': r.scoreLabel,
        'scoreValue': r.scoreValue,
      }).toList(),
    };
  }

  factory HifzEntryModel.fromJson(Map<dynamic, dynamic> json) {
    return HifzEntryModel(
      id: json['id'] as String? ?? '',
      surahId: (json['surahId'] as num?)?.toInt() ?? 0,
      startVerse: (json['startVerse'] as num?)?.toInt() ?? 1,
      endVerse: (json['endVerse'] as num?)?.toInt() ?? 1,
      title: json['title'] as String?,
      status: _parseStatus(json['status']),
      memorizedDate: parseDateTime(json['memorizedDate']) ?? DateTime.now(),
      lastReviewedDate: parseDateTime(json['lastReviewedDate']) ?? DateTime.now(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      reviewStreak: (json['reviewStreak'] as num?)?.toInt() ?? 0,
      weakCount: (json['weakCount'] as num?)?.toInt() ?? 0,
      reviewHistory: _parseHistory(json['reviewHistory']),
    );
  }

  static HifzStatus _parseStatus(dynamic raw) {
    final index = (raw as num?)?.toInt() ?? 0;
    if (index >= 0 && index < HifzStatus.values.length) {
      return HifzStatus.values[index];
    }
    Logger.warning('Out-of-range HifzStatus index: $index, defaulting to newLesson', feature: 'HifzLocal');
    return HifzStatus.newLesson;
  }

  static List<ReviewLog> _parseHistory(dynamic raw) {
    if (raw is! List) return [];
    final result = <ReviewLog>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        result.add(ReviewLog(
          date: parseDateTime(e['date']) ?? DateTime.now(),
          scoreLabel: e['scoreLabel'] as String? ?? '',
          scoreValue: (e['scoreValue'] as num?)?.toInt() ?? 0,
        ));
      } catch (_) {
        continue;
      }
    }
    return result;
  }
}

import '../../domain/entities/recitation_session.dart';

class RecitationSessionModel extends RecitationSession {
  const RecitationSessionModel({
    required super.id,
    required super.surahId,
    required super.surahName,
    required super.totalVerses,
    required super.correctCount,
    required super.totalCount,
    required super.score,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahId': surahId,
      'surahName': surahName,
      'totalVerses': totalVerses,
      'correctCount': correctCount,
      'totalCount': totalCount,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecitationSessionModel.fromJson(Map<dynamic, dynamic> json) {
    return RecitationSessionModel(
      id: json['id'] as String,
      surahId: (json['surahId'] as num).toInt(),
      surahName: json['surahName'] as String,
      totalVerses: (json['totalVerses'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

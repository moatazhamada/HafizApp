import 'package:equatable/equatable.dart';

class RecitationSession extends Equatable {
  final String id;
  final int surahId;
  final String surahName;
  final int totalVerses;
  final int correctCount;
  final int totalCount;
  final double score;
  final DateTime createdAt;

  const RecitationSession({
    required this.id,
    required this.surahId,
    required this.surahName,
    required this.totalVerses,
    required this.correctCount,
    required this.totalCount,
    required this.score,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, surahId, createdAt];
}

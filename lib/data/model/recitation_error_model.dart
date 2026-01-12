import 'package:equatable/equatable.dart';

class RecitationErrorModel extends Equatable {
  final int surahId;
  final String surahName;
  final int verseId;
  final DateTime createdAt;
  final int count;

  const RecitationErrorModel({
    required this.surahId,
    required this.surahName,
    required this.verseId,
    required this.createdAt,
    this.count = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'surahName': surahName,
      'verseId': verseId,
      'createdAt': createdAt.toIso8601String(),
      'count': count,
    };
  }

  factory RecitationErrorModel.fromJson(Map<dynamic, dynamic> json) {
    return RecitationErrorModel(
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String,
      verseId: json['verseId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      count: json['count'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [surahId, surahName, verseId, createdAt, count];
}

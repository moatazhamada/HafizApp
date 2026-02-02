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
    final surahIdRaw = json['surahId'];
    final verseIdRaw = json['verseId'];
    final countRaw = json['count'];

    return RecitationErrorModel(
      surahId: (surahIdRaw as num?)?.toInt() ?? int.parse('$surahIdRaw'),
      surahName: json['surahName'] as String,
      verseId: (verseIdRaw as num?)?.toInt() ?? int.parse('$verseIdRaw'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      count: (countRaw as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [surahId, surahName, verseId, createdAt, count];
}

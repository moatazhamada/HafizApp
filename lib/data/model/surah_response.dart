import '../../domain/entities/verse.dart';

class ChapterResponse {
  final List<VerseModel> chapters;

  ChapterResponse({required this.chapters});

  factory ChapterResponse.fromJson(Map<String, dynamic> json) {
    // API v4 "verses" or legacy "chapter"
    final dynamic raw = json.containsKey('verses')
        ? json['verses']
        : json['chapter'];
    final List<dynamic> list = raw is List ? raw : const [];

    final List<VerseModel> chapters = list
        .map((item) => VerseModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ChapterResponse(chapters: chapters);
  }
}

class VerseModel extends Verse {
  const VerseModel({
    required int chapter,
    required int verse,
    required String text,
    String? translationText,
    int audioTimestampMs = 0,
  }) : super(
         chapterNumber: chapter,
         verseNumber: verse,
         arabicText: text,
         translationText: translationText,
         audioTimestampMs: audioTimestampMs,
       );

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    final dynamic chapterRaw = json['chapter'] ?? json['chapter_id'];
    final int chapter =
        (chapterRaw as num?)?.toInt() ?? int.tryParse('$chapterRaw') ?? 0;

    final dynamic verseRaw = json['verse'] ?? json['verse_number'];
    final int verse =
        (verseRaw as num?)?.toInt() ??
        int.tryParse('$verseRaw') ??
        int.tryParse(
          ((json['verse_key'] as String?) ?? '0:0').split(':').last,
        ) ??
        0;

    return VerseModel(
      chapter: chapter,
      verse: verse,
      text: (json['text'] ?? json['text_uthmani'] ?? '') as String,
    );
  }
}

import '../../domain/entities/verse.dart';

class ChapterResponse {
  final List<VerseModel> chapters;

  ChapterResponse({required this.chapters});

  factory ChapterResponse.fromJson(Map<String, dynamic> json) {
    // API v4 "verses" or legacy "chapter"
    final List<dynamic> list = json.containsKey('verses')
        ? json['verses']
        : json['chapter'];

    final List<VerseModel> chapters = list
        .map((item) => VerseModel.fromJson(item))
        .toList();

    return ChapterResponse(chapters: chapters);
  }
}

class VerseModel extends Verse {
  const VerseModel({
    required int chapter,
    required int verse,
    required super.text,
  }) : super(chapterId: chapter, verseNumber: verse);

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    // API v4 structure
    // verses": [{"id":1,"verse_key":"1:1","text_uthmani":"...","chapter_id":1}]
    // Or legacy structure: {"chapter":1, "verse":1, "text": "..."}

    // Checking keys to support both or stick to legacy if RemoteDataSource handles normalization
    // RemoteDataSourceImpl currently normalizes to legacy shape or uses specific keys.
    // Let's assume input JSON is the normalized one produced by Remote/Local DataSource or raw.

    // Based on RemoteDataSourceImpl:
    // It creates Chapter objects manually or calls fromJson.
    // LocalDataSource calls fromJson directly with legacy structure.

    return VerseModel(
      chapter: json['chapter'] ?? json['chapter_id'],
      verse: json['verse'] ?? json['verse_number'] ?? 0,
      text: json['text'] ?? json['text_uthmani'] ?? '',
    );
  }
}

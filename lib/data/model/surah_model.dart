import 'package:hafiz_app/domain/entities/surah.dart';

/// Data model for Surah, maps between API responses and domain entities
class SurahModel {
  final int chapterNumber;
  final String arabicName;
  final String englishName;
  final int verseCount;
  final bool hasAudio;
  final bool isDownloaded;
  final DateTime? lastDownloadedAt;

  const SurahModel({
    required this.chapterNumber,
    required this.arabicName,
    required this.englishName,
    required this.verseCount,
    required this.hasAudio,
    this.isDownloaded = false,
    this.lastDownloadedAt,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      chapterNumber: json['chapter'] as int,
      arabicName: json['name_arabic'] as String,
      englishName: json['name'] as String,
      verseCount: json['number_of_ayahs'] as int,
      hasAudio: json['has_audio'] as bool? ?? false,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      lastDownloadedAt: json['last_downloaded_at'] != null
          ? DateTime.parse(json['last_downloaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapterNumber,
      'name_arabic': arabicName,
      'name': englishName,
      'number_of_ayahs': verseCount,
      'has_audio': hasAudio,
      'is_downloaded': isDownloaded,
      if (lastDownloadedAt != null)
        'last_downloaded_at': lastDownloadedAt!.toIso8601String(),
    };
  }

  Surah toEntity() {
    return Surah(
      chapterNumber: chapterNumber,
      arabicName: arabicName,
      englishName: englishName,
      verseCount: verseCount,
      hasAudio: hasAudio,
      isDownloaded: isDownloaded,
      lastDownloadedAt: lastDownloadedAt,
    );
  }

  SurahModel copyWith({
    int? chapterNumber,
    String? arabicName,
    String? englishName,
    int? verseCount,
    bool? hasAudio,
    bool? isDownloaded,
    DateTime? lastDownloadedAt,
  }) {
    return SurahModel(
      chapterNumber: chapterNumber ?? this.chapterNumber,
      arabicName: arabicName ?? this.arabicName,
      englishName: englishName ?? this.englishName,
      verseCount: verseCount ?? this.verseCount,
      hasAudio: hasAudio ?? this.hasAudio,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastDownloadedAt: lastDownloadedAt ?? this.lastDownloadedAt,
    );
  }

  factory SurahModel.fromEntity(Surah surah) {
    return SurahModel(
      chapterNumber: surah.chapterNumber,
      arabicName: surah.arabicName,
      englishName: surah.englishName,
      verseCount: surah.verseCount,
      hasAudio: surah.hasAudio,
      isDownloaded: surah.isDownloaded,
      lastDownloadedAt: surah.lastDownloadedAt,
    );
  }
}

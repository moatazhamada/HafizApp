import 'package:equatable/equatable.dart';

/// Represents a Quran chapter (Surah) with metadata and audio availability status
class Surah extends Equatable {
  final int chapterNumber;
  final String arabicName;
  final String englishName;
  final int verseCount;
  final bool hasAudio;
  final bool isDownloaded;
  final DateTime? lastDownloadedAt;

  const Surah({
    required this.chapterNumber,
    required this.arabicName,
    required this.englishName,
    required this.verseCount,
    required this.hasAudio,
    this.isDownloaded = false,
    this.lastDownloadedAt,
  });

  @override
  List<Object?> get props => [
    chapterNumber,
    arabicName,
    englishName,
    verseCount,
    hasAudio,
    isDownloaded,
    lastDownloadedAt,
  ];

  Surah copyWith({
    int? chapterNumber,
    String? arabicName,
    String? englishName,
    int? verseCount,
    bool? hasAudio,
    bool? isDownloaded,
    DateTime? lastDownloadedAt,
  }) {
    return Surah(
      chapterNumber: chapterNumber ?? this.chapterNumber,
      arabicName: arabicName ?? this.arabicName,
      englishName: englishName ?? this.englishName,
      verseCount: verseCount ?? this.verseCount,
      hasAudio: hasAudio ?? this.hasAudio,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      lastDownloadedAt: lastDownloadedAt ?? this.lastDownloadedAt,
    );
  }
}

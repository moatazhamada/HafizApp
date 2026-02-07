class Reciter {
  final int id;
  final String name;
  final String? style;
  final String? language;

  const Reciter({
    required this.id,
    required this.name,
    this.style,
    this.language,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as int? ?? 0,
      name: json['reciter_name']?.toString() ??
          json['name']?.toString() ??
          '',
      style: json['style']?.toString(),
      language: json['language']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reciter_name': name,
      'style': style,
      'language': language,
    };
  }
}

class WordSegment {
  final int wordIndex;
  final int startMs;
  final int endMs;

  const WordSegment({
    required this.wordIndex,
    required this.startMs,
    required this.endMs,
  });

  factory WordSegment.fromList(List<dynamic> data) {
    return WordSegment(
      wordIndex: data[0] as int? ?? 0,
      startMs: data[1] as int? ?? 0,
      endMs: data[2] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_index': wordIndex,
      'start_ms': startMs,
      'end_ms': endMs,
    };
  }
}

class VerseTiming {
  final String verseKey;
  final int timestampFrom;
  final int timestampTo;
  final List<WordSegment> segments;

  const VerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.segments,
  });

  factory VerseTiming.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'];
    final segments = segmentsJson is List
        ? segmentsJson
            .whereType<List>()
            .map((e) => WordSegment.fromList(e))
            .toList()
        : <WordSegment>[];
    return VerseTiming(
      verseKey: json['verse_key']?.toString() ?? '',
      timestampFrom: json['timestamp_from'] as int? ?? 0,
      timestampTo: json['timestamp_to'] as int? ?? 0,
      segments: segments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verse_key': verseKey,
      'timestamp_from': timestampFrom,
      'timestamp_to': timestampTo,
      'segments': segments
          .map((s) => [s.wordIndex, s.startMs, s.endMs])
          .toList(),
    };
  }
}

class ChapterAudioFile {
  final String audioUrl;
  final List<VerseTiming> timings;

  const ChapterAudioFile({
    required this.audioUrl,
    required this.timings,
  });

  factory ChapterAudioFile.fromJson(Map<String, dynamic> json) {
    final audioUrl = json['audio_url']?.toString() ?? '';
    final timestampData = json['timestamps'];
    final timings = timestampData is List
        ? timestampData
            .map((e) => VerseTiming.fromJson(e as Map<String, dynamic>))
            .toList()
        : <VerseTiming>[];
    return ChapterAudioFile(audioUrl: audioUrl, timings: timings);
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_url': audioUrl,
      'timestamps': timings.map((t) => t.toJson()).toList(),
    };
  }
}

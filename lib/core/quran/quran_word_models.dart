/// Per-word data for a verse, sourced from QF Content API.
class QuranWord {
  final int id;
  final int position;
  final String verseKey;
  final String textUthmani;
  final String? transliteration;
  final String? audioUrl;
  final String charType;

  const QuranWord({
    required this.id,
    required this.position,
    required this.verseKey,
    required this.textUthmani,
    this.transliteration,
    this.audioUrl,
    required this.charType,
  });

  bool get isWord => charType == 'word';

  /// Full audio URL using the standard QF CDN prefix.
  String? get fullAudioUrl {
    if (audioUrl == null || audioUrl!.isEmpty) return null;
    if (audioUrl!.startsWith('http')) return audioUrl;
    return 'https://audio.qurancdn.com/$audioUrl';
  }

  factory QuranWord.fromJson(Map<String, dynamic> json) {
    return QuranWord(
      id: json['id'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      verseKey: json['verse_key']?.toString() ?? '',
      textUthmani: json['text_uthmani']?.toString() ?? '',
      transliteration: json['transliteration'] is Map
          ? (json['transliteration'] as Map)['text']?.toString()
          : json['transliteration']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      charType: json['char_type_name']?.toString() ?? 'word',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'verse_key': verseKey,
      'text_uthmani': textUthmani,
      'transliteration': transliteration,
      'audio_url': audioUrl,
      'char_type_name': charType,
    };
  }
}

/// Verse-level word data container.
class VerseWordData {
  final String verseKey;
  final List<QuranWord> words;

  const VerseWordData({
    required this.verseKey,
    required this.words,
  });

  /// Words only (excludes verse-end markers).
  List<QuranWord> get spokenWords =>
      words.where((w) => w.isWord).toList();

  /// Get transliteration for a word by its 1-based position index.
  String? transliterationAt(int position) {
    final word = words.where(
      (w) => w.position == position && w.isWord,
    );
    return word.isNotEmpty ? word.first.transliteration : null;
  }

  /// Get audio URL for a word by its 1-based position index.
  String? audioUrlAt(int position) {
    final word = words.where(
      (w) => w.position == position && w.isWord,
    );
    return word.isNotEmpty ? word.first.fullAudioUrl : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'verse_key': verseKey,
      'words': words.map((w) => w.toJson()).toList(),
    };
  }

  factory VerseWordData.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'];
    final words = wordsJson is List
        ? wordsJson
            .whereType<Map<String, dynamic>>()
            .map((e) => QuranWord.fromJson(e))
            .toList()
        : <QuranWord>[];
    return VerseWordData(
      verseKey: json['verse_key']?.toString() ?? '',
      words: words,
    );
  }
}

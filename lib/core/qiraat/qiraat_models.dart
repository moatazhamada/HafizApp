class QiraatEdition {
  final String identifier;
  final String name;
  final String? englishName;
  final String language;
  final String format;
  final String type;
  final String? direction;

  const QiraatEdition({
    required this.identifier,
    required this.name,
    required this.language,
    required this.format,
    required this.type,
    this.englishName,
    this.direction,
  });

  factory QiraatEdition.fromJson(Map<String, dynamic> json) {
    return QiraatEdition(
      identifier: json['identifier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString(),
      language: json['language']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      direction: json['direction']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'name': name,
      'englishName': englishName,
      'language': language,
      'format': format,
      'type': type,
      'direction': direction,
    };
  }
}

class QiraatAyah {
  final int number;
  final int numberInSurah;
  final String text;

  const QiraatAyah({
    required this.number,
    required this.numberInSurah,
    required this.text,
  });

  factory QiraatAyah.fromJson(Map<String, dynamic> json) {
    return QiraatAyah(
      number: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'numberInSurah': numberInSurah,
      'text': text,
    };
  }
}

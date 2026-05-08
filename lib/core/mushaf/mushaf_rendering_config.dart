class MushafRenderingConfig {
  static const String quranHubApiBase = 'https://api.quranhub.com/v1';

  static String editionId(String mushafType) {
    switch (mushafType) {
      case 'tajweed':
        return 'quran-tajweed';
      case 'naskh':
      case 'warsh':
      case 'shemerly':
      case 'madani':
      default:
        return 'quran-uthmani';
    }
  }

  // ─── Tajweed Parsing (kept for future use) ──────────────────────

  static const Map<String, int> _tajweedColors = {
    'h': 0xFF00AA00,
    'n': 0xFF0000FF,
    'p': 0xFFFF0000,
    'l': 0xFF8B4513,
    'm': 0xFFFF8C00,
  };

  static const String _tajweedTagPattern = r'\[([hnplm]):?([^\]]*)\]';

  static List<TajweedSegment> parseTajweedTags(String text) {
    final segments = <TajweedSegment>[];
    final regex = RegExp(_tajweedTagPattern);
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(
          TajweedSegment(text: text.substring(lastEnd, match.start)),
        );
      }
      final tag = match.group(1)!;
      final inner = match.group(2)!;
      final colorValue = _tajweedColors[tag] ?? 0xFF000000;
      segments.add(TajweedSegment(text: inner, colorValue: colorValue));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TajweedSegment(text: text.substring(lastEnd)));
    }

    return segments;
  }
}

class TajweedSegment {
  final String text;
  final int? colorValue;

  const TajweedSegment({required this.text, this.colorValue});
}

class MushafRenderingConfig {
  static const String _everyAyahBase = 'https://everyayah.com/data/images_png';

  static const String quranHubApiBase = 'https://api.quranhub.com/v1';

  static const String textMode = 'text';
  static const String ayahImagesMode = 'ayahImages';
  static const String glyphMode = 'glyph';
  static const String tajweedMode = 'tajweed';

  static String editionId(String mushafType) {
    switch (mushafType) {
      case 'tajweed':
        return 'quran-tajweed';
      case 'naskh':
      case 'warsh':
      case 'egyptian':
      case 'madani':
      default:
        return 'quran-uthmani';
    }
  }

  static String ayahImageUrl(
    int surahId,
    int ayahNumber, {
    String mushafType = 'madani',
  }) {
    return '$_everyAyahBase/${surahId}_$ayahNumber.png';
  }

  static String? pageImageZipUrl(String mushafType) {
    switch (mushafType) {
      case 'madani':
      case 'egyptian':
        return 'https://android.quran.com/data/zips/images_1280.zip';
      default:
        return null;
    }
  }

  static bool isTajweed(String mushafType) => mushafType == 'tajweed';

  static bool isWarsh(String mushafType) => mushafType == 'warsh';

  static bool usesTajweedMode(String renderingMode, String mushafType) =>
      renderingMode == tajweedMode || isTajweed(mushafType);

  // ─── Full-Page Image URLs ───────────────────────────────────────

  static String pageImageUrl(
    int pageNumber, {
    String mushafType = 'madani',
    int width = 1024,
  }) {
    final paddedPage = pageNumber.toString().padLeft(3, '0');
    switch (mushafType) {
      case 'madani':
        return 'https://files.quran.app/hafs/madani/width_$width/page$paddedPage.png';
      case 'warsh':
        final w = width > 1260 ? 1260 : width;
        return 'https://files.quran.app/warsh/original/width_$w/page$paddedPage.png';
      case 'naskh':
        return 'https://files.quran.app/hafs/naskh/width_1280/page$paddedPage.png';
      case 'egyptian':
        return 'https://archive.org/download/shamerly/$paddedPage.png';
      default:
        return 'https://files.quran.app/hafs/madani/width_$width/page$paddedPage.png';
    }
  }

  static int totalPagesForType(String mushafType) {
    switch (mushafType) {
      case 'naskh':
        return 612;
      case 'egyptian':
        return 522;
      default:
        return 604;
    }
  }

  static int optimalWidth(double screenWidth) {
    if (screenWidth <= 400) return 480;
    if (screenWidth <= 800) return 800;
    if (screenWidth <= 1100) return 1024;
    return 1260;
  }

  static bool hasPageImages(String mushafType) {
    return mushafType == 'madani' || mushafType == 'warsh';
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

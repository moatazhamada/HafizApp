enum RecitationStrictness { lenient, normal, strict }

class ArabicNormalizer {
  static final RegExp _diacritics = RegExp(r'[\u064B-\u0652\u0670\u0671]');
  static final RegExp _punctuation = RegExp(
    r'[\u060C\u061B\u061F\u06D4\u06D6-\u06ED\ufdf2\ufdfa]',
  );

  static String forRecitation(
    String text, {
    RecitationStrictness strictness = RecitationStrictness.normal,
  }) {
    String result = text;

    result = _stripPunctuation(result);
    result = _stripTatweel(result);
    result = _expandShadda(result);
    result = _normalizeHamzaVariants(result);
    result = _normalizeAlifMaqsura(result);
    result = _normalizeTaMarbuta(result);
    result = _handleSilentTerminalAlif(result);
    result = _stripDiacritics(result);
    result = _normalizeMadd(result);

    if (strictness != RecitationStrictness.strict) {
      result = _normalizeQalqalahFuzzy(result);
    }
    if (strictness == RecitationStrictness.lenient) {
      result = _normalizeHamsFuzzy(result);
    }

    return result.trim();
  }

  static String forDisplay(String text) {
    String result = text;
    result = _stripPunctuation(result);
    result = _stripTatweel(result);
    result = _stripDiacritics(result);
    return result.trim();
  }

  static String normalizeWord(String word) {
    return forRecitation(word, strictness: RecitationStrictness.normal);
  }

  static List<String> toPhonemes(
    String text, {
    RecitationStrictness strictness = RecitationStrictness.normal,
  }) {
    String normalized = forRecitation(text, strictness: strictness);
    return _tokenize(normalized);
  }

  // --- Private helpers ---

  static String _stripPunctuation(String text) {
    return text.replaceAll(_punctuation, ' ');
  }

  static String _stripTatweel(String text) {
    return text.replaceAll('\u0640', '');
  }

  static String _stripDiacritics(String text) {
    return text.replaceAll(_diacritics, '');
  }

  static String _expandShadda(String text) {
    // Simply strip shadda — STT typically outputs a single letter for doubled
    // consonants, so expanding would create a mismatch. The edit-distance
    // alignment handles the 1-vs-2 letter difference gracefully.
    return text.replaceAll('\u0651', '');
  }

  static String _normalizeHamzaVariants(String text) {
    String result = text;
    result = result.replaceAll('\u0622', '\u0627\u0627'); // آ → اا
    result = result.replaceAll('\u0623', '\u0627'); // أ → ا
    result = result.replaceAll('\u0625', '\u0627'); // إ → ا
    result = result.replaceAll('\u0671', '\u0627'); // ٱ → ا
    result = result.replaceAll('\u0624', '\u0648'); // ؤ → و
    result = result.replaceAll('\u0626', '\u064A'); // ئ → ي
    result = result.replaceAll('\u0621', ''); // ء → (remove)
    return result;
  }

  static String _normalizeAlifMaqsura(String text) {
    return text.replaceAll('\u0649', '\u064A'); // ى → ي
  }

  static String _normalizeTaMarbuta(String text) {
    return text.replaceAll('\u0629', '\u0647'); // ة → ه
  }

  static String _handleSilentTerminalAlif(String text) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) return text;

    final result = <String>[];
    for (final token in tokens) {
      result.add(_stripSilentTerminalAlifInWord(token));
    }
    return result.join(' ');
  }

  static String _stripSilentTerminalAlifInWord(String word) {
    if (word.length < 2) return word;

    final tanweenFatha = '\u064B';
    final alif = '\u0627';

    if (word.endsWith(alif) && word.contains(tanweenFatha)) {
      final tanweenIdx = word.lastIndexOf(tanweenFatha);
      if (tanweenIdx >= 0 && tanweenIdx < word.length - 1) {
        return word.substring(0, word.length - 1);
      }
    }

    return word;
  }

  static String _normalizeMadd(String text) {
    String result = text;
    result = result.replaceAll('\u0627\u064E', '\u0627');
    result = result.replaceAll('\u0648\u064F', '\u0648');
    result = result.replaceAll('\u064A\u0650', '\u064A');
    return result;
  }

  static String _normalizeQalqalahFuzzy(String text) {
    const qalqalahMap = {
      '\u0642': '\u0643', // ق → ك
      '\u0637': '\u062A', // ط → ت
      '\u0628': '\u062A', // ب → ت
      '\u062C': '\u0634', // ج → ش
      '\u062F': '\u0630', // د → ذ
    };

    String result = text;
    for (final entry in qalqalahMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static String _normalizeHamsFuzzy(String text) {
    const hamsMap = {
      '\u062A': '\u0637', // ت → ط
      '\u062B': '\u0633', // ث → س
      '\u062D': '\u0647', // ح → ه
      '\u062E': '\u0647', // خ → ه
      '\u0633': '\u0635', // س → ص
      '\u0634': '\u0633', // ش → س
      '\u0635': '\u0633', // ص → س
      '\u0641': '\u062B', // ف → ث
      '\u0643': '\u0642', // ك → ق
      '\u0647': '\u062D', // ه → ح
    };

    String result = text;
    for (final entry in hamsMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static List<String> _tokenize(String input) {
    final cleaned = input.replaceAll(_punctuation, ' ');
    return cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  static List<String> orderedTokens(String text) {
    return _tokenize(forRecitation(text));
  }
}

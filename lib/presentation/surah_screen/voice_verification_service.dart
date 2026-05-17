import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class VoiceVerificationService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  // Default thresholds tuned for lenient, coach-like feedback.
  static const double defaultPassThreshold = 0.85;
  static const int defaultMinWords = 3;

  Future<bool> initialize() async {
    // Just simple check, actual init with UI prompt happens on listen usually or explicit init
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) => Logger.warning('STT Error: $error', feature: 'VoiceVerification'),
        onStatus: (status) => Logger.info('STT Status: $status', feature: 'VoiceVerification'),
      );
      return _isAvailable;
    } catch (e) {
      Logger.warning('STT Init Failed: $e', feature: 'VoiceVerification');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    // First initialization attempt - this triggers the permission dialog if needed
    bool result = await initialize();

    if (!result) {
      // If failed, wait a moment for permission dialog to complete
      // Then retry once - handles case where user just granted permission
      await Future.delayed(const Duration(milliseconds: 500));
      result = await initialize();
    }

    return result;
  }

  /// Check if speech recognition is currently available without re-initializing
  bool get isAvailable => _isAvailable;

  Future<void> listen({
    required Function(String) onResult,
    required Function(String) onDone,
    String localeId = 'ar_SA', // Default to Arabic
  }) async {
    if (!_isAvailable) {
      Logger.warning('STT not available', feature: 'VoiceVerification');
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onDone(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    await _speechToText.stop();
  }

  Future<void> dispose() async {
    await _speechToText.cancel();
    await _speechToText.stop();
  }

  /// Analyze spoken vs expected text and return a structured assessment.
  ///
  /// Runs on the main isolate for small texts. For longer texts or when
  /// called from the UI thread, prefer [analyzeRecitationAsync].
  RecitationAnalysis analyzeRecitation(
    String spokenText,
    String expectedText, {
    bool allowPartial = true,
    double passThreshold = defaultPassThreshold,
    int minWords = defaultMinWords,
  }) {
    // Tokenize, merge single letters (like Alif Lam Mim), then normalize
    final tokensSpoken = _mergeSingleLetterTokens(_tokenize(spokenText))
        .map(_normalizeArabic)
        .toList();
    final tokensExpected = _mergeSingleLetterTokens(_tokenize(expectedText))
        .map(_normalizeArabic)
        .toList();

    final isTooShort = tokensSpoken.length < minWords;

    _AlignmentResult aligned = _align(tokensExpected, tokensSpoken);

    if (allowPartial && tokensSpoken.isNotEmpty) {
      final best = _bestPartialAlignment(tokensExpected, tokensSpoken);
      if (best.score > aligned.score) aligned = best;
    }

    final score = aligned.score;
    final passed = !isTooShort && score >= passThreshold;

    return RecitationAnalysis(
      score: score,
      passed: passed,
      isTooShort: isTooShort,
      issues: aligned.issues,
      expectedRange: aligned.expectedRange,
    );
  }

  /// Async variant of [analyzeRecitation] that offloads the edit-distance
  /// computation to a background isolate to avoid jank.
  Future<RecitationAnalysis> analyzeRecitationAsync(
    String spokenText,
    String expectedText, {
    bool allowPartial = true,
    double passThreshold = defaultPassThreshold,
    int minWords = defaultMinWords,
  }) async {
    return compute(_analyzeRecitationWorker, <String, dynamic>{
      'spokenText': spokenText,
      'expectedText': expectedText,
      'allowPartial': allowPartial,
      'passThreshold': passThreshold,
      'minWords': minWords,
    });
  }

  static RecitationAnalysis _analyzeRecitationWorker(Map<String, dynamic> params) {
    return VoiceVerificationService().analyzeRecitation(
      params['spokenText'] as String,
      params['expectedText'] as String,
      allowPartial: params['allowPartial'] as bool,
      passThreshold: params['passThreshold'] as double,
      minWords: params['minWords'] as int,
    );
  }

  // Basic normalization for comparison
  String _normalizeArabic(String input) {
    // Remove Tashkeel (Diacritics)
    // Range: 064B - 0652 (Fathatan, Dammatan, Kasratan, Fatha, Damma, Kasra, Shadda, Sukun)
    // Also 0670 (Superscript Alef)
    // Also remove Tatweel (0640)
    String text = input;
    text = text.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');

    // Normalize Alefs
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');

    // Normalize Ya/Alef Maqsura
    text = text.replaceAll('ى', 'ي');

    // Normalize Ta Marbuta
    text = text.replaceAll('ة', 'ه');

    return text.trim();
  }

  List<String> _tokenize(String input) {
    // Split on whitespace and common Arabic punctuation/stop signs
    final cleaned = input.replaceAll(
      RegExp(r'[\u060C\u061B\u061F\u06D4\u06D6-\u06ED]'),
      ' ',
    );
    return cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  List<String> _mergeSingleLetterTokens(List<String> tokens) {
    if (tokens.isEmpty) return tokens;
    final merged = <String>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        merged.add(buffer.toString());
        buffer.clear();
      }
    }

    for (final t in tokens) {
      final isSingleLetter = t.length == 1 && _isArabicLetter(t);
      if (isSingleLetter) {
        buffer.write(t);
      } else {
        flush();
        merged.add(t);
      }
    }
    flush();
    return merged;
  }

  bool _isArabicLetter(String input) {
    return RegExp(r'^[\u0621-\u064A]$').hasMatch(input);
  }

  _AlignmentResult _align(List<String> expected, List<String> spoken) {
    if (expected.isEmpty && spoken.isEmpty) {
      return const _AlignmentResult(
        score: 1,
        issues: [],
        expectedRange: ExpectedRange(0, -1),
      );
    }

    final int m = expected.length;
    final int n = spoken.length;

    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    final op = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = expected[i - 1] == spoken[j - 1] ? 0 : 1;
        final del = dp[i - 1][j] + 1;
        final ins = dp[i][j - 1] + 1;
        final sub = dp[i - 1][j - 1] + cost;

        int best = del;
        int bestOp = 1; // delete
        if (ins < best) {
          best = ins;
          bestOp = 2; // insert
        }
        if (sub < best) {
          best = sub;
          bestOp = cost == 0 ? 0 : 3; // match or substitute
        }

        dp[i][j] = best;
        op[i][j] = bestOp;
      }
    }

    final issues = <RecitationIssue>[];
    int i = m;
    int j = n;
    while (i > 0 || j > 0) {
      final action = op[i][j];
      if (i > 0 && j > 0 && action == 0) {
        i--;
        j--;
      } else if (i > 0 && j > 0 && action == 3) {
        issues.add(RecitationIssue.substitute(
          expected: expected[i - 1],
          actual: spoken[j - 1],
        ));
        i--;
        j--;
      } else if (i > 0 && (j == 0 || action == 1)) {
        issues.add(RecitationIssue.missing(expected[i - 1]));
        i--;
      } else if (j > 0) {
        issues.add(RecitationIssue.extra(spoken[j - 1]));
        j--;
      }
    }

    final distance = dp[m][n];
    final denom = (m > n ? m : n).clamp(1, 999999);
    final score = 1 - (distance / denom);

    return _AlignmentResult(
      score: score,
      issues: issues.reversed.toList(),
      expectedRange: ExpectedRange(0, m - 1),
    );
  }

  _AlignmentResult _bestPartialAlignment(
    List<String> expected,
    List<String> spoken,
  ) {
    if (expected.isEmpty || spoken.isEmpty) {
      return const _AlignmentResult(
        score: 0,
        issues: [],
        expectedRange: ExpectedRange(0, -1),
      );
    }

    final int window = spoken.length;
    if (window >= expected.length) return _align(expected, spoken);

    _AlignmentResult best = const _AlignmentResult(
      score: -1,
      issues: [],
      expectedRange: ExpectedRange(0, -1),
    );

    for (int start = 0; start <= expected.length - window; start++) {
      final slice = expected.sublist(start, start + window);
      final result = _align(slice, spoken);
      if (result.score > best.score) {
        best = _AlignmentResult(
          score: result.score,
          issues: result.issues,
          expectedRange: ExpectedRange(start, start + window - 1),
        );
      }
    }

    return best;
  }
}

class RecitationAnalysis {
  final double score;
  final bool passed;
  final bool isTooShort;
  final List<RecitationIssue> issues;
  final ExpectedRange expectedRange;

  RecitationAnalysis({
    required this.score,
    required this.passed,
    required this.isTooShort,
    required this.issues,
    required this.expectedRange,
  });

  int get missingCount =>
      issues.where((i) => i.type == RecitationIssueType.missing).length;
  int get extraCount =>
      issues.where((i) => i.type == RecitationIssueType.extra).length;
  int get substituteCount =>
      issues.where((i) => i.type == RecitationIssueType.substitute).length;
}

enum RecitationIssueType { missing, extra, substitute }

class RecitationIssue {
  final RecitationIssueType type;
  final String? expected;
  final String? actual;

  RecitationIssue._({
    required this.type,
    this.expected,
    this.actual,
  });

  factory RecitationIssue.missing(String expected) {
    return RecitationIssue._(type: RecitationIssueType.missing, expected: expected);
  }

  factory RecitationIssue.extra(String actual) {
    return RecitationIssue._(type: RecitationIssueType.extra, actual: actual);
  }

  factory RecitationIssue.substitute({
    required String expected,
    required String actual,
  }) {
    return RecitationIssue._(
      type: RecitationIssueType.substitute,
      expected: expected,
      actual: actual,
    );
  }
}

class ExpectedRange {
  final int start;
  final int end;
  const ExpectedRange(this.start, this.end);

  bool get isValid => end >= start && start >= 0;
}

class _AlignmentResult {
  final double score;
  final List<RecitationIssue> issues;
  final ExpectedRange expectedRange;
  const _AlignmentResult({
    required this.score,
    required this.issues,
    required this.expectedRange,
  });
}

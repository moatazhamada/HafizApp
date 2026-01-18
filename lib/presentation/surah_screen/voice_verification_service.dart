import 'package:speech_to_text/speech_to_text.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/foundation.dart';

class VoiceVerificationService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    // Just simple check, actual init with UI prompt happens on listen usually or explicit init
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('STT Init Failed: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    return await initialize();
  }

  Future<void> listen({
    required Function(String) onResult,
    required Function(String) onDone,
    String localeId = 'ar_SA', // Default to Arabic
  }) async {
    if (!_isAvailable) {
      debugPrint('STT not available');
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
      listenMode: ListenMode.dictation,
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    await _speechToText.stop();
  }

  /// Compares spoken text with verse text and returns a list of differences.
  /// This is a basic implementation. For Quran, complex normalization (remove diacritics)
  /// is usually needed for better accuracy.
  List<Diff> verifyRecitation(String spokenText, String verseText) {
    // 1. Normalize both texts (remove diacritics, normalize alef, etc)
    final normSpoken = _normalizeArabic(spokenText);
    final normVerse = _normalizeArabic(verseText);

    final dmp = DiffMatchPatch();
    // dmp.Diff_Timeout = 1.0;
    final diffs = dmp.diff(normVerse, normSpoken);

    // Cleanup semantics usually makes diffs more human-readable
    dmp.diffCleanupSemantic(diffs);

    return diffs;
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
}

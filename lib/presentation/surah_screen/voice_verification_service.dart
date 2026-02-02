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
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
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

    // First try standard diff
    var diffs = dmp.diff(normVerse, normSpoken);
    dmp.diffCleanupSemantic(diffs);

    // Calculate error ratio
    int errorChars = diffs
        .where((d) => d.operation != DIFF_EQUAL)
        .fold(0, (sum, d) => sum + d.text.length);

    // If there are errors, check if disregarding spaces solves it
    // This handles "أ ل م" (spoken) matching "الم" (written)
    if (errorChars > 0) {
      final nSpokenNoSpace = normSpoken.replaceAll(' ', '');
      final nVerseNoSpace = normVerse.replaceAll(' ', '');

      if (nSpokenNoSpace == nVerseNoSpace) {
        // Perfect match ignoring spaces! Return equal
        return [Diff(DIFF_EQUAL, normVerse)];
      }

      // Also try to re-diff the no-space versions if they are close?
      // For now, if exact match fails, we stick to original diff
      // to allow user to see where they might have added words.
    }

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

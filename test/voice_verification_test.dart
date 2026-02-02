import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/presentation/surah_screen/voice_verification_service.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

void main() {
  late VoiceVerificationService service;

  setUp(() {
    service = VoiceVerificationService();
  });

  group('VoiceVerificationService', () {
    test('Standard match should return equal', () {
      final diffs = service.verifyRecitation('الحمد لله', 'الحمد لله');
      expect(diffs.length, 1);
      expect(diffs.first.operation, DIFF_EQUAL);
    });

    test('Disjointed letters (Alif Lam Mim) should match despite spaces', () {
      // Expected (Quran text): "الم"
      // Spoken (STT output): "أ ل م" or "ا ل م"

      const expected = 'الم';
      const spoken = 'أ ل م'; // Typical STT output for separate letters

      final diffs = service.verifyRecitation(spoken, expected);

      // Should be considered Equal after fallback normalization
      expect(diffs.length, 1);
      expect(diffs.first.operation, DIFF_EQUAL);
    });

    test('Normalization handles Alef variations', () {
      const expected = 'ألهاكم';
      const spoken = 'الهاكم'; // Missing Hamza

      final diffs = service.verifyRecitation(spoken, expected);
      expect(diffs.first.operation, DIFF_EQUAL);
    });

    test('Normalization handles Tashkeel removal', () {
      const expected = 'بِسْمِ اللَّهِ'; // With Tashkeel
      const spoken = 'بسم الله'; // Without

      final diffs = service.verifyRecitation(spoken, expected);
      expect(diffs.first.operation, DIFF_EQUAL);
    });
  });
}

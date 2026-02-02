import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/presentation/surah_screen/voice_verification_service.dart';

void main() {
  late VoiceVerificationService service;

  setUp(() {
    service = VoiceVerificationService();
  });

  group('VoiceVerificationService', () {
    test('Standard match should return equal', () {
      final analysis =
          service.analyzeRecitation('الحمد لله', 'الحمد لله');
      expect(analysis.passed, true);
    });

    test('Disjointed letters (Alif Lam Mim) should match despite spaces', () {
      // Expected (Quran text): "الم"
      // Spoken (STT output): "أ ل م" or "ا ل م"

      const expected = 'الم';
      const spoken = 'أ ل م'; // Typical STT output for separate letters

      final analysis = service.analyzeRecitation(spoken, expected);
      expect(analysis.passed, true);
    });

    test('Normalization handles Alef variations', () {
      const expected = 'ألهاكم';
      const spoken = 'الهاكم'; // Missing Hamza

      final analysis = service.analyzeRecitation(spoken, expected);
      expect(analysis.passed, true);
    });

    test('Normalization handles Tashkeel removal', () {
      const expected = 'بِسْمِ اللَّهِ'; // With Tashkeel
      const spoken = 'بسم الله'; // Without

      final analysis = service.analyzeRecitation(spoken, expected);
      expect(analysis.passed, true);
    });
  });
}

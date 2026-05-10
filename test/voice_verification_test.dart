import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/presentation/surah_screen/voice_verification_service.dart';
import 'package:hafiz_app/core/quran/arabic_normalizer.dart';

void main() {
  late VoiceVerificationService service;

  setUp(() {
    service = VoiceVerificationService();
  });

  group('VoiceVerificationService', () {
    test('Standard match should return equal', () {
      final analysis = service.analyzeRecitation(
        'الحمد لله',
        'الحمد لله',
        minWords: 2,
      );
      expect(analysis.passed, true);
    });

    test('Disjointed letters (Alif Lam Mim) should match despite spaces', () {
      const expected = 'الم';
      const spoken = 'أ ل م';

      final analysis = service.analyzeRecitation(spoken, expected, minWords: 1);
      expect(analysis.passed, true);
    });

    test('Normalization handles Alef variations', () {
      const expected = 'ألهاكم';
      const spoken = 'الهاكم';

      final analysis = service.analyzeRecitation(spoken, expected, minWords: 1);
      expect(analysis.passed, true);
    });

    test('Normalization handles Tashkeel removal', () {
      const expected = 'بِسْمِ اللَّهِ';
      const spoken = 'بسم الله';

      final analysis = service.analyzeRecitation(spoken, expected, minWords: 2);
      expect(analysis.passed, true);
    });

    test('Bismillah word-by-word normalization matches', () {
      // Test that core normalization handles Hamzat Wasl correctly
      expect(
        ArabicNormalizer.normalizeWord('بسم'),
        equals(ArabicNormalizer.normalizeWord('بِسْمِ')),
      );
      expect(
        ArabicNormalizer.normalizeWord('الله'),
        equals(ArabicNormalizer.normalizeWord('ٱللَّهِ')),
      );
      expect(
        ArabicNormalizer.normalizeWord('الرحمن'),
        equals(ArabicNormalizer.normalizeWord('ٱلرَّحْمَـٰنِ')),
      );
      expect(
        ArabicNormalizer.normalizeWord('الرحيم'),
        equals(ArabicNormalizer.normalizeWord('ٱلرَّحِيمِ')),
      );
    });

    test('Al-Fatihah 1:5 word-by-word matches', () {
      expect(
        ArabicNormalizer.normalizeWord('اياك'),
        equals(ArabicNormalizer.normalizeWord('إِيَّاكَ')),
      );
      expect(
        ArabicNormalizer.normalizeWord('نعبد'),
        equals(ArabicNormalizer.normalizeWord('نَعْبُدُ')),
      );
      expect(
        ArabicNormalizer.normalizeWord('نستعين'),
        equals(ArabicNormalizer.normalizeWord('نَسْتَعِينُ')),
      );
    });

    test('Missing words reported correctly', () {
      final analysis = service.analyzeRecitation(
        'بسم الله',
        'بسم الله الرحمن الرحيم',
        minWords: 2,
        allowPartial: false,
      );
      expect(analysis.missingCount, greaterThan(0));
    });

    test('Too short recitation flagged', () {
      final analysis = service.analyzeRecitation(
        'بسم',
        'بسم الله الرحمن الرحيم',
        minWords: 3,
      );
      expect(analysis.isTooShort, true);
      expect(analysis.passed, false);
    });

    test('Extra words reported correctly', () {
      final analysis = service.analyzeRecitation(
        'بسم الله الرحمن الرحيم كثير',
        'بسم الله الرحمن الرحيم',
        minWords: 4,
      );
      expect(analysis.extraCount, greaterThan(0));
    });

    test('Partial alignment finds best substring', () {
      final analysis = service.analyzeRecitation(
        'الرحمن الرحيم',
        'بسم الله الرحمن الرحيم',
        minWords: 2,
        allowPartial: true,
      );
      expect(analysis.expectedRange.isValid, true);
      expect(analysis.score, greaterThan(0.5));
    });

    test('Empty spoken text returns too short', () {
      final analysis = service.analyzeRecitation('', 'بسم الله', minWords: 1);
      expect(analysis.isTooShort, true);
    });

    test('Exact match scores 1.0', () {
      final analysis = service.analyzeRecitation(
        'بسم الله الرحمن الرحيم',
        'بسم الله الرحمن الرحيم',
        minWords: 4,
      );
      expect(analysis.score, equals(1.0));
      expect(analysis.issues, isEmpty);
    });

    test('Strictness parameter via ArabicNormalizer', () {
      final normalResult = ArabicNormalizer.forRecitation(
        'ٱلْحَمْدُ لِلَّهِ',
        strictness: RecitationStrictness.normal,
      );
      final strictResult = ArabicNormalizer.forRecitation(
        'ٱلْحَمْدُ لِلَّهِ',
        strictness: RecitationStrictness.strict,
      );
      // Both should strip ٱ
      expect(normalResult, isNot(contains('\u0671')));
      expect(strictResult, isNot(contains('\u0671')));
    });
  });
}

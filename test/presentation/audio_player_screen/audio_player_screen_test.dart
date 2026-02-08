import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

void main() {
  group('AudioPlayerScreen parameters', () {
    test('Surah can be created with required parameters', () {
      final surah = Surah(1, 'Al-Fatiha', 'الفاتحة');
      
      expect(surah.id, 1);
      expect(surah.nameEnglish, 'Al-Fatiha');
      expect(surah.nameArabic, 'الفاتحة');
    });

    test('Surah has correct verse count', () {
      final surah = Surah(1, 'Al-Fatiha', 'الفاتحة');
      
      expect(surah.verseCount, 7);
    });

    test('all 114 surahs exist', () {
      for (int i = 1; i <= 114; i++) {
        final surah = Surah(i, 'Test', 'تست');
        expect(surah.id, i);
        expect(surah.verseCount, greaterThan(0));
      }
    });
  });
}

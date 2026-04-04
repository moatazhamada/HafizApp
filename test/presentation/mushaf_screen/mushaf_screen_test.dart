import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

void main() {
  group('MushafScreen parameters', () {
    test('all Mushaf types can be passed as parameters', () {
      // Verify all Mushaf types are valid for use with MushafScreen
      for (final type in allMushafTypes) {
        expect(type, isNotNull);
        expect(type.totalPages, greaterThan(0));
      }
    });

    test('Madani Mushaf has correct properties', () {
      expect(MushafType.madani.totalPages, 604);
      expect(MushafType.madani.prefsKey, 'madani');
    });

    test('Indo-Pak Mushaf has correct properties', () {
      expect(MushafType.indoPak.totalPages, 558);
      expect(MushafType.indoPak.prefsKey, 'indopak');
    });
  });
}

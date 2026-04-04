import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

void main() {
  group('App Integration Tests', () {
    test('all Mushaf types are available', () {
      // Verify all Mushaf types exist
      expect(allMushafTypes.length, 4);
      expect(allMushafTypes, contains(MushafType.madani));
      expect(allMushafTypes, contains(MushafType.egyptian));
      expect(allMushafTypes, contains(MushafType.indoPak));
      expect(allMushafTypes, contains(MushafType.warsh));
    });

    test('Mushaf types have correct properties', () {
      for (final type in allMushafTypes) {
        expect(type.displayName, isNotEmpty);
        expect(type.displayNameEn, isNotEmpty);
        expect(type.totalPages, greaterThan(0));
        expect(type.prefsKey, isNotEmpty);
      }
    });

    test('Madani Mushaf has 604 pages', () {
      expect(MushafType.madani.totalPages, 604);
    });

    test('Indo-Pak Mushaf has 558 pages', () {
      expect(MushafType.indoPak.totalPages, 558);
    });

    test('can convert between Mushaf type and string', () {
      expect(mushafTypeFromString('madani'), MushafType.madani);
      expect(mushafTypeFromString('egyptian'), MushafType.egyptian);
      expect(mushafTypeFromString('indopak'), MushafType.indoPak);
      expect(mushafTypeFromString('warsh'), MushafType.warsh);
      expect(mushafTypeFromString('unknown'), MushafType.madani);
    });
  });
}

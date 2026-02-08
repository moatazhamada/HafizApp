import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

void main() {
  group('MushafType', () {
    test('should have correct display names', () {
      expect(MushafType.madani.displayName, 'المصحف المدني (Uthmani)');
      expect(MushafType.egyptian.displayName, 'المصحف المصري (Egyptian)');
      expect(MushafType.indoPak.displayName, 'مصحف الهندوباك (Indo-Pak)');
      expect(MushafType.warsh.displayName, 'مصحف ورش (Warsh)');
    });

    test('should have correct English display names', () {
      expect(MushafType.madani.displayNameEn, 'Madani (Uthmani)');
      expect(MushafType.egyptian.displayNameEn, 'Egyptian (Standard)');
      expect(MushafType.indoPak.displayNameEn, 'Indo-Pak');
      expect(MushafType.warsh.displayNameEn, 'Warsh (North African)');
    });

    test('should have correct page counts', () {
      expect(MushafType.madani.totalPages, 604);
      expect(MushafType.egyptian.totalPages, 604);
      expect(MushafType.indoPak.totalPages, 558);
      expect(MushafType.warsh.totalPages, 604);
    });

    test('should have correct prefs keys', () {
      expect(MushafType.madani.prefsKey, 'madani');
      expect(MushafType.egyptian.prefsKey, 'egyptian');
      expect(MushafType.indoPak.prefsKey, 'indopak');
      expect(MushafType.warsh.prefsKey, 'warsh');
    });

    test('should have unique icons', () {
      final icons = allMushafTypes.map((t) => t.icon).toSet();
      expect(icons.length, allMushafTypes.length);
    });

    test('should have unique primary colors', () {
      final colors = allMushafTypes.map((t) => t.primaryColor).toSet();
      expect(colors.length, allMushafTypes.length);
    });
  });

  group('mushafTypeFromString', () {
    test('should return correct type for valid keys', () {
      expect(mushafTypeFromString('madani'), MushafType.madani);
      expect(mushafTypeFromString('egyptian'), MushafType.egyptian);
      expect(mushafTypeFromString('indopak'), MushafType.indoPak);
      expect(mushafTypeFromString('warsh'), MushafType.warsh);
    });

    test('should return madani as default for unknown keys', () {
      expect(mushafTypeFromString('unknown'), MushafType.madani);
      expect(mushafTypeFromString(''), MushafType.madani);
    });
  });

  group('allMushafTypes', () {
    test('should contain all four types', () {
      expect(allMushafTypes.length, 4);
      expect(allMushafTypes, contains(MushafType.madani));
      expect(allMushafTypes, contains(MushafType.egyptian));
      expect(allMushafTypes, contains(MushafType.indoPak));
      expect(allMushafTypes, contains(MushafType.warsh));
    });
  });

  group('MushafType descriptions', () {
    test('should have non-empty descriptions', () {
      for (final type in allMushafTypes) {
        expect(type.description, isNotEmpty);
        expect(type.description.length, greaterThan(20));
      }
    });

    test('descriptions should contain region information', () {
      expect(MushafType.madani.description, contains('Saudi'));
      expect(MushafType.egyptian.description, contains('Egypt'));
      expect(MushafType.indoPak.description, contains('India'));
      expect(MushafType.warsh.description, contains('Morocco'));
    });
  });
}

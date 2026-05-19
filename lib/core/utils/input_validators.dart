import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';

/// Validation function signature. Returns an error message string when invalid,
/// or `null` when the value is valid.
typedef ValidatorFn = String? Function(String? value);

/// Centralized input validators for the Hafiz app.
///
/// All validators return `null` when the input is valid, or a localized
/// error message string when invalid.
class InputValidators {
  InputValidators._();

  /// Checks that the trimmed value is not empty.
  static ValidatorFn required() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'val_required'.tr;
      }
      return null;
    };
  }

  /// Checks that the value does not exceed [max] characters.
  static ValidatorFn maxLength(int max) {
    return (String? value) {
      if (value != null && value.length > max) {
        return 'val_max_length'.tr.replaceAll('{max}', max.toString());
      }
      return null;
    };
  }

  /// Checks that the value is at least [min] characters.
  static ValidatorFn minLength(int min) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        return 'val_min_length'.tr.replaceAll('{min}', min.toString());
      }
      return null;
    };
  }

  /// Validates that the value is a valid integer within an optional range.
  static ValidatorFn numericRange({int? min, int? max}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'val_required'.tr;
      }
      final parsed = int.tryParse(value.trim());
      if (parsed == null) {
        return 'val_invalid_number'.tr;
      }
      if (min != null && parsed < min) {
        return 'val_min_value'.tr.replaceAll('{min}', min.toString());
      }
      if (max != null && parsed > max) {
        return 'val_max_value'.tr.replaceAll('{max}', max.toString());
      }
      return null;
    };
  }

  /// Validates a positive integer (≥ 1).
  static ValidatorFn positiveInteger() {
    return numericRange(min: 1);
  }

  /// Validates a Mushaf page number for the given [type].
  static ValidatorFn quranPageNumber(MushafType type) {
    return (String? value) {
      final baseError = numericRange(min: 1, max: type.totalPages)(value);
      if (baseError != null) {
        return 'val_quran_page_range'
            .tr.replaceAll('{max}', type.totalPages.toString());
      }
      return null;
    };
  }

  /// Validates a Surah number (1–114).
  static ValidatorFn quranSurahNumber() {
    return (String? value) {
      final baseError = numericRange(min: 1, max: 114)(value);
      if (baseError != null) {
        return 'val_quran_surah_range'.tr;
      }
      return null;
    };
  }

  /// Validates a Juz number (1–30).
  static ValidatorFn quranJuzNumber() {
    return (String? value) {
      final baseError = numericRange(min: 1, max: 30)(value);
      if (baseError != null) {
        return 'val_quran_juz_range'.tr;
      }
      return null;
    };
  }

  /// Validates an Ayah number for a specific Surah.
  static ValidatorFn quranVerseNumber(int surahId) {
    return (String? value) {
      final verseCount = MushafPageIndex.getVerseCount(surahId);
      final baseError = numericRange(min: 1, max: verseCount)(value);
      if (baseError != null) {
        return 'val_quran_verse_range'
            .tr.replaceAll('{max}', verseCount.toString());
      }
      return null;
    };
  }

  /// Combines multiple validators and returns the first error encountered.
  static ValidatorFn compose(List<ValidatorFn> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

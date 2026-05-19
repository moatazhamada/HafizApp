import 'package:flutter/services.dart';

/// Pre-built input formatters for reuse across the app.
class AppInputFormatters {
  AppInputFormatters._();

  /// Allows only digits (0–9).
  static final TextInputFormatter digitsOnly = FilteringTextInputFormatter.digitsOnly;

  /// Creates a formatter that limits input to [max] characters.
  static TextInputFormatter maxLength(int max) {
    return LengthLimitingTextInputFormatter(max);
  }

  /// Prevents leading whitespace from being entered.
  static final TextInputFormatter noLeadingSpaces = FilteringTextInputFormatter.deny(
    RegExp(r'^\s+'),
  );

  /// Allows Arabic script, spaces, and common punctuation.
  /// Useful for search fields and reflection inputs.
  static final TextInputFormatter arabicText = FilteringTextInputFormatter.allow(
    RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s\.,!?؛،؟\-]'),
  );
}

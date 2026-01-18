import 'package:flutter/material.dart';

extension NumberConverter on int {
  String toLocalizedNumber(BuildContext context) {
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return toString()
          .replaceAll('0', '٠')
          .replaceAll('1', '١')
          .replaceAll('2', '٢')
          .replaceAll('3', '٣')
          .replaceAll('4', '٤')
          .replaceAll('5', '٥')
          .replaceAll('6', '٦')
          .replaceAll('7', '٧')
          .replaceAll('8', '٨')
          .replaceAll('9', '٩');
    }
    return toString();
  }
}

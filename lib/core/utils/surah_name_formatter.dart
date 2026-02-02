import 'package:flutter/material.dart';
import '../quran_index/quran_surah.dart';

extension SurahNameFormatter on Surah {
  String localizedName(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (isAr) return nameArabic;
    return '$nameEnglish - $nameArabic';
  }
}

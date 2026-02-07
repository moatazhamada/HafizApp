import 'dart:convert';
import 'package:flutter/material.dart';

class QuranIndex {
  static List<Surah> quranSurahs = [
    Surah(1, 'Al-Fatiha', 'الفاتحة'),
    Surah(2, 'Al-Baqarah', 'البقرة'),
    Surah(3, 'Aal-E-Imran', 'آل عمران'),
    Surah(4, 'An-Nisa', 'النساء'),
    Surah(5, 'Al-Ma\'idah', 'المائدة'),
    Surah(6, 'Al-An\'am', 'الأنعام'),
    Surah(7, 'Al-A\'raf', 'الأعراف'),
    Surah(8, 'Al-Anfal', 'الأنفال'),
    Surah(9, 'At-Tawbah', 'التوبة'),
    Surah(10, 'Yunus', 'يونس'),
    Surah(11, 'Hud', 'هود'),
    Surah(12, 'Yusuf', 'يوسف'),
    Surah(13, 'Ar-Ra\'d', 'الرعد'),
    Surah(14, 'Ibrahim', 'إبراهيم'),
    Surah(15, 'Al-Hijr', 'الحجر'),
    Surah(16, 'An-Nahl', 'النحل'),
    Surah(17, 'Al-Isra', 'الإسراء'),
    Surah(18, 'Al-Kahf', 'الكهف'),
    Surah(19, 'Maryam', 'مريم'),
    Surah(20, 'Ta-Ha', 'طه'),
    Surah(21, 'Al-Anbiya', 'الأنبياء'),
    Surah(22, 'Al-Hajj', 'الحج'),
    Surah(23, 'Al-Mu\'minun', 'المؤمنون'),
    Surah(24, 'An-Nur', 'النور'),
    Surah(25, 'Al-Furqan', 'الفرقان'),
    Surah(26, 'Ash-Shu\'ara', 'الشعراء'),
    Surah(27, 'An-Naml', 'النمل'),
    Surah(28, 'Al-Qasas', 'القصص'),
    Surah(29, 'Al-Ankabut', 'العنكبوت'),
    Surah(30, 'Ar-Rum', 'الروم'),
    Surah(31, 'Luqman', 'لقمان'),
    Surah(32, 'As-Sajda', 'السجدة'),
    Surah(33, 'Al-Ahzab', 'الأحزاب'),
    Surah(34, 'Saba', 'سبأ'),
    Surah(35, 'Fatir', 'فاطر'),
    Surah(36, 'Ya-Sin', 'يس'),
    Surah(37, 'As-Saffat', 'الصافات'),
    Surah(38, 'Sad', 'ص'),
    Surah(39, 'Az-Zumar', 'الزمر'),
    Surah(40, 'Ghafir', 'غافر'),
    Surah(41, 'Fussilat', 'فصلت'),
    Surah(42, 'Ash-Shura', 'الشورى'),
    Surah(43, 'Az-Zukhruf', 'الزخرف'),
    Surah(44, 'Ad-Dukhan', 'الدخان'),
    Surah(45, 'Al-Jathiya', 'الجاثية'),
    Surah(46, 'Al-Ahqaf', 'الأحقاف'),
    Surah(47, 'Muhammad', 'محمد'),
    Surah(48, 'Al-Fath', 'الفتح'),
    Surah(49, 'Al-Hujurat', 'الحجرات'),
    Surah(50, 'Qaf', 'ق'),
    Surah(51, 'Adh-Dhariyat', 'الذاريات'),
    Surah(52, 'At-Tur', 'الطور'),
    Surah(53, 'An-Najm', 'النجم'),
    Surah(54, 'Al-Qamar', 'القمر'),
    Surah(55, 'Ar-Rahman', 'الرحمن'),
    Surah(56, 'Al-Waqi\'a', 'الواقعة'),
    Surah(57, 'Al-Hadid', 'الحديد'),
    Surah(58, 'Al-Mujadila', 'المجادلة'),
    Surah(59, 'Al-Hashr', 'الحشر'),
    Surah(60, 'Al-Mumtahina', 'الممتحنة'),
    Surah(61, 'As-Saff', 'الصف'),
    Surah(62, 'Al-Jumu\'a', 'الجمعة'),
    Surah(63, 'Al-Munafiqun', 'المنافقون'),
    Surah(64, 'At-Taghabun', 'التغابن'),
    Surah(65, 'At-Talaq', 'الطلاق'),
    Surah(66, 'At-Tahrim', 'التحريم'),
    Surah(67, 'Al-Mulk', 'الملك'),
    Surah(68, 'Al-Qalam', 'القلم'),
    Surah(69, 'Al-Haaqqa', 'الحاقة'),
    Surah(70, 'Al-Ma\'arij', 'المعارج'),
    Surah(71, 'Nuh', 'نوح'),
    Surah(72, 'Al-Jinn', 'الجن'),
    Surah(73, 'Al-Muzzammil', 'المزمل'),
    Surah(74, 'Al-Muddathir', 'المدثر'),
    Surah(75, 'Al-Qiyama', 'القيامة'),
    Surah(76, 'Al-Insan', 'الإنسان'),
    Surah(77, 'Al-Mursalat', 'المرسلات'),
    Surah(78, 'An-Naba', 'النبأ'),
    Surah(79, 'An-Nazi\'at', 'النازعات'),
    Surah(80, 'Abasa', 'عبس'),
    Surah(81, 'At-Takwir', 'التكوير'),
    Surah(82, 'Al-Infitar', 'الإنفطار'),
    Surah(83, 'Al-Mutaffifin', 'المطففين'),
    Surah(84, 'Al-Inshiqaq', 'الإنشقاق'),
    Surah(85, 'Al-Burooj', 'البروج'),
    Surah(86, 'At-Tariq', 'الطارق'),
    Surah(87, 'Al-Ala', 'الأعلى'),
    Surah(88, 'Al-Ghashiya', 'الغاشية'),
    Surah(89, 'Al-Fajr', 'الفجر'),
    Surah(90, 'Al-Balad', 'البلد'),
    Surah(91, 'Ash-Shams', 'الشمس'),
    Surah(92, 'Al-Lail', 'الليل'),
    Surah(93, 'Adh-Dhuhaa', 'الضحى'),
    Surah(94, 'Ash-Sharh', 'الشرح'),
    Surah(95, 'At-Tin', 'التين'),
    Surah(96, 'Al-Alaq', 'العلق'),
    Surah(97, 'Al-Qadr', 'القدر'),
    Surah(98, 'Al-Bayyina', 'البينة'),
    Surah(99, 'Az-Zalzalah', 'الزلزلة'),
    Surah(100, 'Al-Adiyat', 'العاديات'),
    Surah(101, 'Al-Qaria', 'القارعة'),
    Surah(102, 'At-Takathur', 'التكاثر'),
    Surah(103, 'Al-Asr', 'العصر'),
    Surah(104, 'Al-Humazah', 'الهمزة'),
    Surah(105, 'Al-Fil', 'الفيل'),
    Surah(106, 'Quraish', 'قريش'),
    Surah(107, 'Al-Ma\'un', 'الماعون'),
    Surah(108, 'Al-Kawthar', 'الكوثر'),
    Surah(109, 'Al-Kafiroon', 'الكافرون'),
    Surah(110, 'An-Nasr', 'النصر'),
    Surah(111, 'Al-Masad', 'المسد'),
    Surah(112, 'Al-Ikhlas', 'الإخلاص'),
    Surah(113, 'Al-Falaq', 'الفلق'),
    Surah(114, 'An-Nas', 'الناس'),
  ];
}

class Surah {
  final int id;
  final String nameEnglish;
  final String nameArabic;

  Surah(this.id, this.nameEnglish, this.nameArabic);

  /// Get verse count for this Surah
  int get verseCount => _verseCounts[id] ?? 0;
  
  /// Get localized name based on current locale
  String localizedName(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? nameArabic : nameEnglish;
  }

  // Convert Surah object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameEnglish': nameEnglish,
      'nameArabic': nameArabic,
    };
  }

  // Factory method to create Surah object from a Map
  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      map['id'],
      map['nameEnglish'],
      map['nameArabic'],
    );
  }

  // Factory method to create Surah object from JSON string
  factory Surah.fromJson(String source) => Surah.fromMap(json.decode(source));
  
  // Verse counts for each Surah
  static const Map<int, int> _verseCounts = {
    1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75, 9: 129,
    10: 109, 11: 123, 12: 111, 13: 43, 14: 52, 15: 99, 16: 128, 17: 111,
    18: 110, 19: 98, 20: 135, 21: 112, 22: 78, 23: 118, 24: 64, 25: 77,
    26: 227, 27: 93, 28: 88, 29: 69, 30: 60, 31: 34, 32: 30, 33: 73,
    34: 54, 35: 45, 36: 83, 37: 182, 38: 88, 39: 75, 40: 85, 41: 54,
    42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29, 49: 18,
    50: 45, 51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96, 57: 29,
    58: 22, 59: 24, 60: 13, 61: 14, 62: 11, 63: 11, 64: 18, 65: 12,
    66: 12, 67: 30, 68: 52, 69: 52, 70: 44, 71: 28, 72: 28, 73: 20,
    74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42, 81: 29,
    82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30,
    90: 20, 91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19, 97: 5,
    98: 8, 99: 8, 100: 11, 101: 11, 102: 8, 103: 3, 104: 9, 105: 5,
    106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4, 113: 5, 114: 6,
  };
}

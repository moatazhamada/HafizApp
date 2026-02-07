import 'package:flutter/material.dart';

/// Mushaf Types - Different Quran scripts and layouts used worldwide
/// 
/// There are several types of Mushaf with different:
/// - Script/writing styles (Uthmani, Indo-Pak, Warsh, etc.)
/// - Page layouts and pagination
/// - Tashkeel (diacritical marks) styles
/// - Verse numbering
enum MushafType {
  /// Uthmani/Madani Script (most common)
  /// - Used in Saudi Arabia and most Arab countries
  /// - 604 pages (standard)
  /// - Clear Uthmani script
  /// - Used by Quran.com
  madani,
  
  /// Indo-Pak Script (South Asian)
  /// - Used in India, Pakistan, Bangladesh
  /// - Different page count (~558 pages)
  /// - Larger script, more spacing
  /// - Different tashkeel style
  indoPak,
  
  /// Warsh Script (North African)
  /// - Used in Morocco, Algeria, Tunisia
  /// - Different reading (Qira'at Warsh)
  /// - Unique script variations
  warsh,
}

/// Extension to get Mushaf type details
extension MushafTypeExtension on MushafType {
  /// Display name
  String get displayName {
    switch (this) {
      case MushafType.madani:
        return 'المصحف المدني (Uthmani)';
      case MushafType.indoPak:
        return 'مصحف الهندوباك (Indo-Pak)';
      case MushafType.warsh:
        return 'مصحف ورش (Warsh)';
    }
  }
  
  /// English display name
  String get displayNameEn {
    switch (this) {
      case MushafType.madani:
        return 'Madani (Uthmani)';
      case MushafType.indoPak:
        return 'Indo-Pak';
      case MushafType.warsh:
        return 'Warsh (North African)';
    }
  }
  
  /// Total page count
  int get totalPages {
    switch (this) {
      case MushafType.madani:
        return 604;
      case MushafType.indoPak:
        return 558; // Approximate
      case MushafType.warsh:
        return 604; // Same as Madani but different layout
    }
  }
  
  /// Script/Font family name
  String get fontFamily {
    switch (this) {
      case MushafType.madani:
        return 'Amiri';
      case MushafType.indoPak:
        return 'IndoPak';
      case MushafType.warsh:
        return 'Warsh';
    }
  }
  
  /// Description
  String get description {
    switch (this) {
      case MushafType.madani:
        return 'Standard Uthmani script used in Saudi Arabia and most Arab countries';
      case MushafType.indoPak:
        return 'South Asian script with larger text and different spacing, used in India, Pakistan';
      case MushafType.warsh:
        return 'North African script used in Morocco, Algeria, Tunisia with unique variations';
    }
  }
  
  /// Storage key for preferences
  String get prefsKey {
    switch (this) {
      case MushafType.madani:
        return 'madani';
      case MushafType.indoPak:
        return 'indopak';
      case MushafType.warsh:
        return 'warsh';
    }
  }
  
  /// Icon representing the type
  IconData get icon {
    switch (this) {
      case MushafType.madani:
        return Icons.menu_book;
      case MushafType.indoPak:
        return Icons.auto_stories;
      case MushafType.warsh:
        return Icons.book;
    }
  }
}

/// Get Mushaf type from string key
MushafType mushafTypeFromString(String key) {
  switch (key) {
    case 'indopak':
      return MushafType.indoPak;
    case 'warsh':
      return MushafType.warsh;
    case 'madani':
    default:
      return MushafType.madani;
  }
}

/// Get all available Mushaf types
List<MushafType> get allMushafTypes => [
  MushafType.madani,
  MushafType.indoPak,
  MushafType.warsh,
];

# Quran Data Handling

## Data Sources

### Primary Source: Local Assets
- Quran text bundled in app at `assets/quran/uthmani/`
- 114 JSON files: `surah_1.json` through `surah_114.json`
- Source: Tanzil.net verified Uthmani text (CC BY-ND 3.0)
- **Never modify the Quran text** - license is CC BY-ND (No Derivatives)

### Fallback Source: Remote API
- Quran.com API v4: `https://api.quran.com/api/v4`
- Only used if local file is missing or corrupted
- Requires internet connection

### Page Index
- File: `assets/quran/mushaf_page_index.json`
- Maps verses to Mushaf page numbers
- Supports multiple Mushaf types (Madani, Indo-Pak, etc.)

## JSON Schema

### Surah File Structure
```json
{
  "chapter": [
    {
      "chapter": 1,
      "verse": 1,
      "text": "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ"
    },
    {
      "chapter": 1,
      "verse": 2,
      "text": "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"
    }
  ]
}
```

### Field Definitions
- `chapter`: Surah number (1-114)
- `verse`: Verse number within the Surah (1-286)
- `text`: Arabic text in Uthmani script with diacritics

### Page Index Structure
```json
{
  "madani": {
    "1": {
      "surah": 1,
      "startVerse": 1,
      "endVerse": 7,
      "isSurahStart": true
    },
    "2": {
      "surah": 2,
      "startVerse": 1,
      "endVerse": 5,
      "isSurahStart": true
    }
  },
  "indopak": {
    // Similar structure with different page counts
  }
}
```

## Quran Structure

### Surah Information
```dart
// All 114 Surahs defined in QuranIndex.quranSurahs
final surah = QuranIndex.quranSurahs[0]; // Al-Fatiha

// Properties
surah.id              // 1
surah.nameEnglish     // "Al-Fatiha"
surah.nameArabic      // "الفاتحة"
surah.verseCount      // 7
```

### Verse Counts by Surah
- Shortest: Surah 108 (Al-Kawthar) - 3 verses
- Longest: Surah 2 (Al-Baqarah) - 286 verses
- Total verses: 6,236 (excluding Bismillah)

### Mushaf Types
```dart
enum MushafType {
  madani,      // 604 pages (Saudi Arabia)
  egyptian,    // 604 pages (Egypt)
  indoPak,     // 558 pages (India/Pakistan)
  warsh,       // 604 pages (North Africa)
}
```

## Bismillah Handling

### Special Cases
- **Surah 1 (Al-Fatiha)**: Bismillah is verse 1
- **Surah 9 (At-Tawbah)**: No Bismillah
- **All other Surahs**: Bismillah precedes verse 1 (not counted as a verse)

### Detection Logic
```dart
bool isBismillah(int surahId, int verseNumber) {
  if (surahId == 1 && verseNumber == 1) return true;
  return false;
}

bool surahHasBismillah(int surahId) {
  return surahId != 9; // All except At-Tawbah
}
```

### Display Logic
- Show Bismillah image/text before verse 1 (except Surah 1 and 9)
- Use `assets/images/bismillah.svg` or `bismillah.png`
- Bismillah is part of verse 1 only in Surah 1

## Verse Numbering

### Addressing Format
- Format: `Surah:Verse` (e.g., `2:255` for Ayat al-Kursi)
- Surah range: 1-114
- Verse range: 1-286 (varies by Surah)

### Validation
```dart
bool isValidVerseReference(int surahId, int verseNumber) {
  if (surahId < 1 || surahId > 114) return false;
  
  final surah = QuranIndex.quranSurahs.firstWhere(
    (s) => s.id == surahId,
    orElse: () => null,
  );
  
  if (surah == null) return false;
  return verseNumber >= 1 && verseNumber <= surah.verseCount;
}
```

## Generating Quran Assets

### From Tanzil Source
1. Download verified text from https://tanzil.net/download/
2. Choose format: `quran-uthmani.txt` (pipe-delimited)
3. Format: `SURAH|VERSE|TEXT` per line

### Generation Script
```bash
# Run the asset generator
dart run tool/generate_quran_assets.dart \
  /path/to/quran-uthmani.txt \
  assets/quran/uthmani
```

### Script Functionality
- Parses Tanzil text file
- Splits into 114 separate JSON files
- Validates verse counts
- Ensures proper UTF-8 encoding
- Preserves diacritics and special characters

### Verification
```bash
# Count files (should be 114)
ls assets/quran/uthmani/*.json | wc -l

# Verify JSON structure
cat assets/quran/uthmani/surah_1.json | jq .

# Check verse count for Al-Baqarah (should be 286)
cat assets/quran/uthmani/surah_2.json | jq '.chapter | length'
```

## Loading Quran Data

### Local Loading
```dart
// Load from assets
final jsonString = await rootBundle.loadString(
  'assets/quran/uthmani/surah_$surahId.json',
);
final data = json.decode(jsonString);
final verses = (data['chapter'] as List)
    .map((v) => Verse.fromJson(v))
    .toList();
```

### Remote Fallback
```dart
// If local fails, fetch from API
final response = await dio.get(
  'https://api.quran.com/api/v4/chapters/$surahId',
);
final verses = parseApiResponse(response.data);
```

### Caching Strategy
1. Try local assets first (always available offline)
2. If missing, fetch from remote API
3. Cache remote data in Hive for offline access
4. Cache key: `surah_$surahId`

## Page Index Usage

### Loading Page Index
```dart
// Load once at app startup
await MushafPageIndex.loadPageDataFromAsset();
```

### Finding Page for Verse
```dart
final pageInfo = MushafPageIndex.getPageForVerse(
  surahId: 2,
  verseNumber: 255,
  mushafType: MushafType.madani,
);

print('Page: ${pageInfo.pageNumber}');
print('Is Surah start: ${pageInfo.isSurahStart}');
```

### Finding Verses on Page
```dart
final verses = MushafPageIndex.getVersesOnPage(
  pageNumber: 1,
  mushafType: MushafType.madani,
);

for (final verse in verses) {
  print('${verse.surahId}:${verse.verseNumber}');
}
```

## Text Processing

### Arabic Text Handling
- Encoding: UTF-8
- Script: Uthmani (with diacritics)
- Direction: RTL (right-to-left)
- Font: Amiri (bundled in app)

### Diacritics
- Fatha: َ
- Kasra: ِ
- Damma: ُ
- Sukun: ْ
- Shadda: ّ
- Tanween: ً ٍ ٌ

### Special Characters
- Hamza: ء أ إ ؤ ئ
- Alif variations: ا آ
- Taa Marbuta: ة
- Alif Maqsura: ى

### Text Comparison
```dart
// For voice verification, normalize text
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // Remove diacritics
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();
}
```

## Data Integrity

### Verification Checklist
- [ ] All 114 Surah files present
- [ ] Verse counts match expected values
- [ ] No corrupted UTF-8 characters
- [ ] Bismillah present in all Surahs except At-Tawbah
- [ ] JSON structure valid
- [ ] File sizes reasonable (1-50 KB per file)

### Checksum Validation
```dart
// Verify file integrity
Future<bool> verifySurahFile(int surahId) async {
  try {
    final jsonString = await rootBundle.loadString(
      'assets/quran/uthmani/surah_$surahId.json',
    );
    final data = json.decode(jsonString);
    final verses = data['chapter'] as List;
    
    final expectedCount = QuranIndex.quranSurahs[surahId - 1].verseCount;
    return verses.length == expectedCount;
  } catch (e) {
    return false;
  }
}
```

## Attribution Requirements

### Tanzil License (CC BY-ND 3.0)
- **Attribution**: Must credit Tanzil.net
- **No Derivatives**: Cannot modify the Quran text
- **Share Alike**: Can redistribute with same license

### In-App Attribution
- Displayed in About screen
- Format: "Quran text from Tanzil.net (CC BY-ND 3.0)"
- Link to source: https://tanzil.net

### Code Comments
```dart
// Quran text source: Tanzil.net
// License: Creative Commons Attribution-NoDerivs 3.0
// DO NOT MODIFY the Arabic text
```

## Common Issues

### Missing Diacritics
- Ensure UTF-8 encoding throughout
- Check font supports all diacritics
- Verify JSON parsing preserves Unicode

### Incorrect Verse Counts
- Verify against official Mushaf
- Check for off-by-one errors
- Validate Bismillah handling

### Page Mapping Errors
- Different Mushaf types have different page breaks
- Verify page index for selected Mushaf type
- Test edge cases (Surah boundaries)

### Performance
- Load Surahs lazily (on demand)
- Cache parsed JSON in memory
- Use Hive for persistent cache
- Avoid loading entire Quran at once

// One-shot CLI script to regenerate all 114 Uthmani JSON assets.
// Usage: dart run scripts/download_uthmani.dart
//
// Fetches from api.quran.com/api/v4 (public, no auth needed).
// Overwrites assets/quran/uthmani/surah_1.json .. surah_114.json

import 'dart:convert';
import 'dart:io';

const String baseUrl = 'https://api.quran.com/api/v4/quran/verses/uthmani';
const String outputDir = 'assets/quran/uthmani';

Future<void> main() async {
  final dir = Directory(outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final client = HttpClient();
  int successCount = 0;
  int failCount = 0;

  for (int chapter = 1; chapter <= 114; chapter++) {
    try {
      final uri = Uri.parse('$baseUrl?chapter_number=$chapter');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        stderr.writeln(
          'ERROR: Surah $chapter returned HTTP ${response.statusCode}',
        );
        failCount++;
        continue;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;
      final verses = data['verses'] as List;

      final List<Map<String, dynamic>> chapterVerses = [];
      for (final verse in verses) {
        final key = verse['verse_key'] as String;
        final parts = key.split(':');
        final verseNum = int.parse(parts[1]);
        final text = verse['text_uthmani'] as String;
        chapterVerses.add({
          'chapter': chapter,
          'verse': verseNum,
          'text': text,
        });
      }

      final outputFile = File('$outputDir/surah_$chapter.json');
      final jsonOutput = const JsonEncoder.withIndent(
        '  ',
      ).convert({'chapter': chapterVerses});
      outputFile.writeAsStringSync('$jsonOutput\n');

      stdout.writeln('✓ Surah $chapter: ${chapterVerses.length} verses');
      successCount++;

      // Be nice to the API
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      stderr.writeln('ERROR: Surah $chapter failed: $e');
      failCount++;
    }
  }

  client.close();

  stdout.writeln('');
  stdout.writeln('Done: $successCount succeeded, $failCount failed');

  if (failCount > 0) {
    exitCode = 1;
  }
}

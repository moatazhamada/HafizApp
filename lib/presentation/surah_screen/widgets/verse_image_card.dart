import 'package:flutter/material.dart';

/// A beautifully styled card widget for sharing a verse as an image.
///
/// Renders with a fixed gradient background, Arabic verse text in Uthmani
/// script, surah attribution, optional translation, and a small watermark.
class VerseImageCard extends StatelessWidget {
  final String arabicText;
  final String surahName;
  final int verseNumber;
  final String? translation;
  final double width;
  final double height;

  const VerseImageCard({
    super.key,
    required this.arabicText,
    required this.surahName,
    required this.verseNumber,
    this.translation,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00332C),
            Color(0xFF006754),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              arabicText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 28,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$surahName — $verseNumber',
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            if (translation != null && translation!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 1,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                translation!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'Shared from Hafiz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

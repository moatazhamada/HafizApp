import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/quran_index/mushaf_types.dart';
import '../../../core/network/mushaf_image_provider.dart';

class InteractiveMushafPage extends StatelessWidget {
  final int pageNumber;
  final MushafType mushafType;
  final bool isDark;
  final void Function(int surahId, int verseNumber)? onVerseTapped;

  const InteractiveMushafPage({
    super.key,
    required this.pageNumber,
    required this.mushafType,
    required this.isDark,
    this.onVerseTapped,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = MushafImageProvider.getImageUrl(mushafType, pageNumber);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F0E6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The physical printed page image
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain, // Maintain authentic aspect ratio
            color: isDark ? Colors.white : null,
            // Simple color blend inversion for dark mode. Real dark mode is tricky with images,
            // but blending it softly with the background color can work well.
            colorBlendMode: isDark ? BlendMode.difference : null,
            progressIndicatorBuilder: (context, url, progress) => Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: progress.progress,
                  strokeWidth: 2,
                  color: Colors.teal,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load page $pageNumber',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Invisible Gesture Overlay
          GestureDetector(
            onTapUp: (details) {
              // TODO: Fetch and iterate through MushafPageCoords JSON.
              // For now, trigger a raw tap to the parent which can load the first Ayah
              // of the page to verify the bottom sheet works on the image view.
              if (onVerseTapped != null) {
                onVerseTapped!(-1, -1);
              }
            },
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

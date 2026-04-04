import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/app_export.dart';
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
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF5F0E6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // The physical printed page image
                  ColorFiltered(
                    colorFilter: isDark
                        ? const ColorFilter.matrix(<double>[
                            -1.0, 0.0, 0.0, 0.0, 255.0, // R
                            0.0, -1.0, 0.0, 0.0, 255.0, // G
                            0.0, 0.0, -1.0, 0.0, 255.0, // B
                            0.0, 0.0, 0.0, 1.0, 0.0, // A
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit
                          .fill, // Fill screen completely without empty space
                      progressIndicatorBuilder: (context, url, progress) =>
                          Center(
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
                            const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'msg_page_load_failed'.tr.replaceAll(
                                '{page}',
                                pageNumber.toString(),
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (onVerseTapped != null)
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) {
                          // TODO: Fetch and iterate through MushafPageCoords JSON.
                          onVerseTapped!(-1, -1);
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

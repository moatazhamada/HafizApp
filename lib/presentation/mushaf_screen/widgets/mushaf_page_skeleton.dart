import 'package:flutter/material.dart';

class MushafPageSkeleton extends StatefulWidget {
  const MushafPageSkeleton({super.key});

  @override
  State<MushafPageSkeleton> createState() => _MushafPageSkeletonState();
}

class _MushafPageSkeletonState extends State<MushafPageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Exact colors from MushafScreen (Madani/default)
    final backgroundColor = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFFEFDF5);
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    // Faint placeholders
    final baseColor = isDark ? Colors.white : Colors.black;
    final placeholderColor = baseColor.withValues(alpha: 0.08);
    final highlightColor = baseColor.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: borderColor, width: 1),
      ),
      child: FadeTransition(
        opacity: _animation,
        child: Column(
          children: [
            // Header mimicking _buildSurahHeader
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              // Use simplified gradient from PageStyle.madani
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A35), const Color(0xFF0B2D28)]
                      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ornament placeholder
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Title placeholder
                  Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Ornament placeholder
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Bismillah placeholder
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      height: 24,
                      width: 180,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // 15 Lines of "Text" (Madani standard)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Standard Madani has 15 lines.
                          // Let's try to fit roughly 15 lines evenly.
                          const lineCount = 15;
                          // Allow flexible spacing

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(lineCount, (index) {
                              return Row(
                                children: [
                                  // Verse text line
                                  Expanded(
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: placeholderColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  // Random verse marker on some lines
                                  if (index % 3 == 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: placeholderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Page footer (page number)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 16,
              width: 40,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

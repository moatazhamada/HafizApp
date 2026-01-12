import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrefUtils().getIsDarkMode()
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        title: const Text("App Guide"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PrefUtils().getIsDarkMode()
            ? Colors.white
            : Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHelpItem(
            context,
            icon: Icons.bookmark_add,
            title: "Bookmarking Logic",
            description:
                "• Tap the Bookmark icon in the top right to bookmark the *first verse* of the Surah (Page Bookmark).\n"
                "• Long-press on any specific Verse number to add a bookmark to that exact Ayah (Verse Bookmark).\n"
                "• This helps you save your exact reading position.",
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          _buildHelpItem(
            context,
            icon: Icons.visibility_off,
            title: "Hifz Mode (Blur)",
            description:
                "• Tap the Eye icon in the top bar to toggle Hifz Mode.\n"
                "• Verses will be blurred to help you test your memorization.\n"
                "• Tap on any blurred verse text to reveal it momentarily.\n"
                "• Use this to practice reciting from memory and checking yourself.",
            color: Colors.amber[800]!,
          ),
          const SizedBox(height: 20),
          _buildHelpItem(
            context,
            icon: Icons.error_outline,
            title: "Recitation Mistakes",
            description:
                "• If you make a mistake while reciting, Long-press the Verse number.\n"
                "• Select 'Mark as Recitation Mistake'.\n"
                "• The verse will be highlighted in red.\n"
                "• Use this to track 'weak verses' that need more review.",
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isDark = PrefUtils().getIsDarkMode();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

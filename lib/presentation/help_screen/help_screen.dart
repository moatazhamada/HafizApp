import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_app_guide'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHelpItem(
            context,
            icon: Icons.bookmark_add,
            title: 'help_bookmark_title'.tr,
            description: 'help_bookmark_desc'.tr,
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          _buildHelpItem(
            context,
            icon: Icons.visibility_off,
            title: 'help_hifz_title'.tr,
            description: 'help_hifz_desc'.tr,
            color: Colors.amber[800]!,
          ),
          const SizedBox(height: 20),
          _buildHelpItem(
            context,
            icon: Icons.error_outline,
            title: 'help_practice_title'.tr,
            description: 'help_practice_desc'.tr,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.of(context).surface
            : AppColors.of(context).surfaceVariant,
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

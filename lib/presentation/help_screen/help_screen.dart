import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          _buildSectionHeader(context, 'help_section_reading'.tr),
          const SizedBox(height: 12),
          _buildHelpItem(
            context,
            icon: Icons.bookmark_add,
            title: 'help_bookmark_title'.tr,
            description: 'help_bookmark_desc'.tr,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            context,
            icon: Icons.visibility_off,
            title: 'help_hifz_title'.tr,
            description: 'help_hifz_desc'.tr,
            color: Colors.amber[800]!,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'help_section_mushaf'.tr),
          const SizedBox(height: 12),
          _buildHelpItem(
            context,
            icon: Icons.menu_book,
            title: 'help_mushaf_title'.tr,
            description: 'help_mushaf_desc'.tr,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            context,
            icon: Icons.zoom_in,
            title: 'help_zoom_title'.tr,
            description: 'help_zoom_desc'.tr,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'help_section_practice'.tr),
          const SizedBox(height: 12),
          _buildHelpItem(
            context,
            icon: Icons.error_outline,
            title: 'help_practice_title'.tr,
            description: 'help_practice_desc'.tr,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            context,
            icon: Icons.mic,
            title: 'help_voice_title'.tr,
            description: 'help_voice_desc'.tr,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'help_section_customization'.tr),
          const SizedBox(height: 12),
          _buildHelpItem(
            context,
            icon: Icons.settings,
            title: 'help_settings_title'.tr,
            description: 'help_settings_desc'.tr,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          _buildTipCard(context),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow,
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: isDark
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                'help_tip_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('help_tip_content'.tr, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

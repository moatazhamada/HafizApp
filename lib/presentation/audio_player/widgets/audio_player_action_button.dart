import 'package:flutter/material.dart';

/// Compact action button used in the audio player bottom actions bar.
class AudioPlayerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const AudioPlayerActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : null;

    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      onPressed: onPressed,
    );
  }
}

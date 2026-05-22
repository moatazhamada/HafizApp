import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

/// A section label used in the settings screen.
class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayLabel = isArabic ? label : label.toUpperCase();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A styled card used for grouping settings tiles.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

/// A selectable option used in bottom sheets.
class Option {
  final String value;
  final String label;
  final bool isKey;

  const Option(this.value, this.label, {this.isKey = true});
}

/// Shows a simple selection bottom sheet.
Future<T?> showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<Option> options,
  required String selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        for (final option in options)
          ListTile(
            title: Text(option.isKey ? option.label.tr : option.label),
            trailing: selected == option.value
                ? const Icon(Icons.check)
                : null,
            onTap: () => Navigator.pop(context, option.value as T),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Parses a 'HH:MM' string into a [TimeOfDay].
TimeOfDay parseTime(String timeStr) {
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

/// Formats a [TimeOfDay] into a 'HH:MM' string.
String formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

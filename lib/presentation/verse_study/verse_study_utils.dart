import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

String stripHtml(String htmlText) {
  final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(regex, '').trim();
}

String tafsirTitleForId(String id) {
  switch (id) {
    case '169':
      return 'Ibn Kathir (Abridged)';
    case '168':
      return "Ma'arif al-Qur'an";
    case '817':
      return 'Tazkirul Quran';
    case '16':
      return 'Muyassar';
    case '93':
      return 'Al-Wasit';
    case '14':
      return 'Ibn Kathir';
    case '15':
      return 'Tabari';
    case '90':
      return 'Qurtubi';
    case '91':
      return "Sa'di";
    case '94':
      return 'Baghawy';
    default:
      return 'Tafsir';
  }
}

List<Map<String, String>> tafsirOptions(BuildContext context) {
  final isAr = AppLocalization.of()?.locale.languageCode == 'ar';
  if (isAr) {
    return const [
      {'id': '16', 'name': 'الميسر'},
      {'id': '93', 'name': 'الوسيط'},
      {'id': '14', 'name': 'ابن كثير'},
      {'id': '15', 'name': 'الطبري'},
      {'id': '90', 'name': 'القرطبي'},
      {'id': '91', 'name': 'السعدي'},
      {'id': '94', 'name': 'البغوي'},
    ];
  }
  return const [
    {'id': '169', 'name': 'Ibn Kathir (Abridged)'},
    {'id': '168', 'name': "Ma'arif al-Qur'an"},
    {'id': '817', 'name': 'Tazkirul Quran'},
  ];
}

const List<Map<String, String>> translationOptions = [
  {'id': '85', 'name': 'Clear Quran'},
  {'id': '131', 'name': 'Pickthall'},
  {'id': '84', 'name': 'Muhsin Khan'},
  {'id': '101', 'name': 'Sahih International'},
];

void showSourceSelector(
  BuildContext context, {
  required String title,
  required List<Map<String, String>> options,
  required String selectedId,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id']!;
                final name = option['name']!;
                final isSelected = id == selectedId;
                return ListTile(
                  title: Text(name),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

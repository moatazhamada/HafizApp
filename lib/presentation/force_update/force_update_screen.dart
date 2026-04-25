import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String message;

  const ForceUpdateScreen({super.key, this.message = ''});

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hafizapp.quran';

  static const _strings = {
    'en': {
      'title': 'Update Required',
      'body':
          'A critical update is required to ensure the accuracy of the Quranic text (Uthmani Rasm).',
      'button': 'Update from Play Store',
    },
    'ar': {
      'title': 'تحديث مطلوب',
      'body': 'يجب تحديث التطبيق لضمان دقة النص القرآني (الرسم العثماني).',
      'button': 'تحديث من المتجر',
    },
  };

  Map<String, String> _tr(Locale locale) {
    final code = locale.languageCode;
    return _strings[code] ?? _strings['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = _tr(View.of(context).platformDispatcher.locale);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.system_update,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr['title']!,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message.isNotEmpty ? message : tr['body']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _openStore,
                            icon: const Icon(Icons.shop),
                            label: Text(tr['button']!),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

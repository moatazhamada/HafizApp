import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import 'package:hafiz_app/injection_container.dart';
import '../../core/analytics/analytics_service.dart';
import 'package:hafiz_app/main.dart' show globalMessengerKey;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Widget builder(BuildContext context) => const AboutScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = PrefUtils().getIsDarkMode();
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
      decoration: TextDecoration.underline,
    );

    void copy(String text) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('lbl_copied'.tr)));
    }

    Future<void> openExternal(String url) async {
      try {
        bool ok = await launchUrlString(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          // Fallback to platform default (may open custom tabs/in-app)
          ok = await launchUrlString(url, mode: LaunchMode.platformDefault);
        }
        if (!ok) {
          globalMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Could not open: $url')),
          );
        }
        if (ok) {
          sl<AnalyticsService>().logLinkOpened(url);
        }
      } catch (e) {
        globalMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }

    Future<void> showFeedbackDialog() async {
      final controller = TextEditingController();
      bool isSending = false;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('about_feedback_title'.tr),
            content: TextField(
              controller: controller,
              maxLines: 6,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: 'about_feedback_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
                child: Text('lbl_cancel'.tr),
              ),
              FilledButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final msg = controller.text.trim();
                        if (msg.isEmpty) return;

                        setState(() => isSending = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('feedback')
                              .add({
                                'message': msg,
                                'timestamp': FieldValue.serverTimestamp(),
                                'platform': Platform.operatingSystem,
                                'version':
                                    '1.1.0', // Hardcoded for now based on pubspec
                              });

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            globalMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('about_feedback_sent'.tr)),
                            );
                            sl<AnalyticsService>().logFeedbackSubmitted(
                              method: 'firestore',
                            );
                          }
                        } catch (e) {
                          setState(() => isSending = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('about_feedback_send'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('about_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'app_name'.tr,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text('about_intro'.tr, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(
                    'about_ack_heading'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('about_ack_idea_by'.tr),
                  subtitle: Text(
                    'https://github.com/abualgait',
                    style: linkStyle,
                  ),
                  onTap: () => openExternal('https://github.com/abualgait'),
                  onLongPress: () => copy('https://github.com/abualgait'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: Text('about_repo_prefix'.tr),
                  subtitle: Text(
                    'https://github.com/abualgait/HafizApp',
                    style: linkStyle,
                  ),
                  onTap: () =>
                      openExternal('https://github.com/abualgait/HafizApp'),
                  onLongPress: () =>
                      copy('https://github.com/abualgait/HafizApp'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('about_maintained_by'.tr),
                  subtitle: Text('Moataz Mohamed', style: linkStyle),
                  onTap: () => openExternal('https://github.com/moatazhamada'),
                  onLongPress: () => copy('https://github.com/moatazhamada'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text('about_current_repo'.tr),
                  subtitle: Text(
                    'https://github.com/moatazhamada/hafizapp',
                    style: linkStyle,
                  ),
                  onTap: () =>
                      openExternal('https://github.com/moatazhamada/hafizapp'),
                  onLongPress: () =>
                      copy('https://github.com/moatazhamada/hafizapp'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text('about_feedback_title'.tr),
                  subtitle: Text('about_feedback_desc'.tr),
                  onTap: showFeedbackDialog,
                  trailing: const Icon(Icons.open_in_new),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text('lbl_contact_email'.tr), // Localized now
                  subtitle: const Text('support@hafizapp.com'),
                  onTap: () => openExternal(
                    'mailto:support@hafizapp.com?subject=Hafiz App Feedback',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(
                    'about_sources_title'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: Text('about_source_quran_api'.tr, style: linkStyle),
                  onTap: () => openExternal('https://api.quran.com/api/v4'),
                  onLongPress: () => copy('https://api.quran.com/api/v4'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: Text('about_source_tanzil'.tr, style: linkStyle),
                  onTap: () => openExternal('https://tanzil.net/download/'),
                  onLongPress: () => copy('https://tanzil.net/download/'),
                  trailing: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'about_integrity_heading'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('about_integrity_body'.tr),
        ],
      ),
    );
  }
}

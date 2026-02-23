import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import 'package:hafiz_app/injection_container.dart';
import '../../core/analytics/analytics_service.dart';
import 'package:hafiz_app/main.dart' show globalMessengerKey;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/platform_info.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  static Widget builder(BuildContext context) => const AboutScreen();

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = info.version);
      }
    } catch (_) {}
  }

  Widget _buildContributorItem(
    BuildContext context, {
    required String name,
    required String role,
    required String url,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        try {
          await launchUrlString(url, mode: LaunchMode.externalApplication);
        } catch (_) {
          await Clipboard.setData(ClipboardData(text: url));
          globalMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('lbl_copied'.tr)),
          );
        }
      },
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
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
            SnackBar(content: Text('${"msg_could_not_open".tr}$url')),
          );
        }
        if (ok) {
          await sl<AnalyticsService>().logLinkOpened(url);
        }
      } catch (e) {
        globalMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('${"msg_could_not_open".tr}$url')),
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
                                'platform': getPlatformLabel(),
                                'version': _version.isNotEmpty
                                    ? _version
                                    : 'Unknown',
                              });

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            globalMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('about_feedback_sent'.tr)),
                            );
                            await sl<AnalyticsService>().logFeedbackSubmitted(
                              method: 'firestore',
                            );
                          }
                        } catch (e) {
                          setState(() => isSending = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${"msg_error_prefix".tr}$e'),
                              ),
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
          if (_version.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'v$_version',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Mohamed Sayed'),
                      const SizedBox(height: 4),
                      Text('https://github.com/abualgait', style: linkStyle),
                    ],
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
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'https://github.com/moatazhamada/hafizapp',
                          style: linkStyle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Private',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('about_private_repo_title'.tr),
                      content: Text('about_private_repo_desc'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('lbl_close'.tr),
                        ),
                      ],
                    ),
                  ),
                  onLongPress: () =>
                      copy('https://github.com/moatazhamada/hafizapp'),
                  trailing: const Icon(Icons.lock_outline, size: 18),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text('about_contributors'.tr),
                  subtitle: Text('about_contributors_desc'.tr),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('about_contributors'.tr),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'about_team_section'.tr,
                              style: Theme.of(ctx).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildContributorItem(
                              ctx,
                              name: 'Mohamed Sayed',
                              role: 'Original Creator',
                              url: 'https://github.com/abualgait',
                            ),
                            const SizedBox(height: 12),
                            _buildContributorItem(
                              ctx,
                              name: 'Moataz Mohamed',
                              role: 'Current Maintainer',
                              url: 'https://github.com/moatazhamada',
                            ),
                            const Divider(height: 24),
                            Text(
                              'about_data_section'.tr,
                              style: Theme.of(ctx).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildContributorItem(
                              context,
                              name: 'Quran.Foundation',
                              role: 'API & Data Provider',
                              url: 'https://quran.foundation',
                            ),
                            const SizedBox(height: 12),
                            _buildContributorItem(
                              context,
                              name: 'Tanzil Project',
                              role: 'Uthmani Text Source',
                              url: 'https://tanzil.net',
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('lbl_close'.tr),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                  title: Text('lbl_contact_email'.tr),
                  subtitle: const Text('support@hafizapp.com'),
                  onTap: () => openExternal(
                    'mailto:support@hafizapp.com?subject=Hafiz App Feedback',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text('about_share_app'.tr),
                  subtitle: Text('about_share_app_desc'.tr),
                  onTap: () async {
                    try {
                      await shareText(
                        'https://play.google.com/store/apps/details?id=com.hafiz.app',
                      );
                      await sl<AnalyticsService>().logLinkOpened('share_app');
                    } catch (_) {}
                  },
                  trailing: const Icon(Icons.share_outlined),
                ),
                ListTile(
                  leading: const Icon(Icons.star_rate_outlined),
                  title: Text('about_rate_app'.tr),
                  subtitle: Text('about_rate_app_desc'.tr),
                  onTap: _openAppReview,
                  trailing: const Icon(Icons.star_outline),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text('lbl_export_data'.tr),
                  subtitle: Text('lbl_export_data_desc'.tr),
                  onTap: _exportData,
                  trailing: const Icon(Icons.chevron_right),
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

  Future<void> _openAppReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await sl<AnalyticsService>().logLinkOpened('in_app_review');
      } else {
        await _openStorePage();
      }
    } catch (e) {
      await _openStorePage();
    }
  }

  Future<void> _openStorePage() async {
    final url = getPlatformLabel() == 'iOS'
        ? 'https://apps.apple.com/app/hafiz/id123456789'
        : 'https://play.google.com/store/apps/details?id=com.hafiz.app';
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('lbl_copied'.tr)));
      }
    }
  }

  Future<void> _exportData() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lbl_export_data'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text('lbl_export_bookmarks'.tr),
              onTap: () => Navigator.pop(context, 'bookmarks'),
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text('lbl_export_practice'.tr),
              onTap: () => Navigator.pop(context, 'practice'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_cancel'.tr),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      final box = result == 'bookmarks'
          ? await Hive.openBox('bookmarks')
          : await Hive.openBox('recitation_errors');

      final data = box.toMap();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('msg_export_success'.tr)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${"msg_export_error".tr}: $e')));
      }
    }
  }

  Future<void> shareText(String text) async {
    try {
      await Share.share(text, subject: 'about_share_subject'.tr);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
      globalMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('lbl_copied'.tr)),
      );
    }
  }
}

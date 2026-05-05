import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/injection_container.dart';
import '../../core/analytics/analytics_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/utils/platform_info.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark
          ? AppColors.of(context).accent
          : AppColors.of(context).primary,
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${"msg_could_not_open".tr}$url')),
            );
          }
        }
        if (ok) {
          await sl<AnalyticsService>().logLinkOpened(url);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${"msg_could_not_open".tr}$url')),
          );
        }
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
                onPressed: isSending
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        controller.dispose();
                      },
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
                          final body = Uri.encodeComponent(
                            '$msg\n\n---\n'
                            'Platform: ${getPlatformLabel()}\n'
                            'Version: ${_version.isNotEmpty ? _version : 'Unknown'}',
                          );
                          final launched = await launchUrlString(
                            'mailto:support@hafizapp.com?subject=Hafiz%20App%20Feedback&body=$body',
                          );

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            controller.dispose();
                            if (launched) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('about_feedback_sent'.tr),
                                ),
                              );
                            } else {
                              await Clipboard.setData(ClipboardData(text: msg));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('msg_feedback_copied'.tr),
                                  ),
                                );
                              }
                            }
                            await sl<AnalyticsService>().logFeedbackSubmitted(
                              method: 'email',
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
                  title: Text('lbl_contact_email'.tr),
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
          const SizedBox(height: 24),
          const MusaliComingSoonCard(),
        ],
      ),
    );
  }
}

class MusaliComingSoonCard extends StatelessWidget {
  const MusaliComingSoonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grass_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'musali_app_name'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'musali_status'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'musali_teaser_desc'.tr,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton.icon(
              onPressed: () {
                NavigatorService.pushNamed(AppRoutes.musaliTeaserScreen);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('musali_watch_now'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

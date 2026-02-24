import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../localization/app_localization.dart';

/// Force Update Service
/// Checks app version against remote config and prompts users to update
class ForceUpdateService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Remote config keys
  static const String _keyMinVersion = 'min_app_version';
  static const String _keyLatestVersion = 'latest_app_version';
  static const String _keyForceUpdateEnabled = 'force_update_enabled';
  static const String _keyUpdateMessage = 'update_message';

  /// Initialize remote config with defaults
  static Future<void> initialize() async {
    await _remoteConfig.setDefaults({
      _keyMinVersion: '8', // Build number
      _keyLatestVersion: '8', // Build number
      _keyForceUpdateEnabled: false,
      _keyUpdateMessage:
          'A new version is available with improvements and bug fixes. Please update for the best experience.',
    });

    try {
      // Set minimum fetch interval based on environment
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Use defaults if fetch fails
      debugPrint('Remote config fetch failed: $e');
    }
  }

  /// Check if app needs force update
  /// Returns UpdateStatus with update requirement info
  static Future<UpdateStatus> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Get values from Remote Config
      final minVersion = _remoteConfig.getString(_keyMinVersion);
      final latestVersion = _remoteConfig.getString(_keyLatestVersion);
      final forceUpdateEnabled = _remoteConfig.getBool(_keyForceUpdateEnabled);

      // Parse build numbers for comparison (more reliable than version strings)
      final minBuildNumber = int.tryParse(minVersion) ?? 0;
      final latestBuildNumber = int.tryParse(latestVersion) ?? 0;

      // Check if force update is needed (current build < minimum required build)
      final needsForceUpdate = currentBuildNumber < minBuildNumber;
      final hasUpdate = currentBuildNumber < latestBuildNumber;

      return UpdateStatus(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        minVersion: minVersion,
        minBuildNumber: minBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        needsForceUpdate: needsForceUpdate && forceUpdateEnabled,
        hasUpdate: hasUpdate,
        updateMessage: _remoteConfig.getString(_keyUpdateMessage),
      );
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return UpdateStatus(
        currentVersion: '0.0.0',
        currentBuildNumber: 0,
        minVersion: '0',
        minBuildNumber: 0,
        latestVersion: '0',
        latestBuildNumber: 0,
        needsForceUpdate: false,
        hasUpdate: false,
        updateMessage: '',
      );
    }
  }

  /// Open app store for update
  static Future<void> openAppStore() async {
    final Uri storeUrl;
    if (Platform.isAndroid) {
      // Replace with your app's package name
      storeUrl = Uri.parse('market://details?id=com.hafiz.app.hafiz_app');
    } else if (Platform.isIOS) {
      // Replace with your App Store ID
      storeUrl = Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
    } else {
      return;
    }

    try {
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web URL
        final webUrl = Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app'
            : 'https://apps.apple.com/app/idYOUR_APP_ID';
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error opening app store: $e');
    }
  }
}

/// Update status model
class UpdateStatus {
  final String currentVersion;
  final int currentBuildNumber;
  final String minVersion;
  final int minBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool needsForceUpdate;
  final bool hasUpdate;
  final String updateMessage;

  const UpdateStatus({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.minVersion,
    required this.minBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.needsForceUpdate,
    required this.hasUpdate,
    required this.updateMessage,
  });
}

/// Force Update Dialog Widget
class ForceUpdateDialog extends StatelessWidget {
  final UpdateStatus status;
  final bool isForceUpdate;

  const ForceUpdateDialog({
    super.key,
    required this.status,
    this.isForceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !isForceUpdate,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E3320) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
            ),
            const SizedBox(width: 8),
            Text(
              'lbl_update_available'.tr,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'msg_update_description'.tr,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVersionInfo(
                    'lbl_current_version'.tr,
                    'v${status.currentVersion} (${status.currentBuildNumber})',
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  _buildVersionInfo(
                    'lbl_latest_version'.tr,
                    'v${status.latestVersion} (${status.latestBuildNumber})',
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'lbl_later'.tr,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(true);
              ForceUpdateService.openAppStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF1E3A35)
                  : const Color(0xFF006754),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download),
            label: Text('lbl_update_now'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(String label, String version, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Show update dialog and return whether user chose to update
Future<bool> showUpdateDialog(
  BuildContext context, {
  required UpdateStatus status,
  bool forceUpdate = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (context) =>
        ForceUpdateDialog(status: status, isForceUpdate: forceUpdate),
  );
  return result ?? false;
}

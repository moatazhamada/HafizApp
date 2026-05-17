import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/notifications/notification_service.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class NotificationPermissionPage extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final String? themeMode;
  final bool isLightBackground;

  const NotificationPermissionPage({
    super.key,
    required this.onContinue,
    required this.onBack,
    this.themeMode,
    this.isLightBackground = false,
  });

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  bool _isLoading = false;

  Future<void> _enableNotifications() async {
    setState(() => _isLoading = true);
    try {
      final service = NotificationService();
      await service.initialize();
      await service.requestPermission();
      // Schedule notifications once permission is handled
      await service.scheduleDailyVerse();
      await service.scheduleReadingReminder();
      await service.scheduleFridayKahf();
    } catch (e) {
      Logger.warning('Notification setup failed: $e', feature: 'Notifications');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onContinue();
      }
    }
  }

  void _skip() {
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLarge = MediaQuery.of(context).size.width > 900;

    return OnboardingScaffold(
      themeMode: widget.themeMode,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 64 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.isLightBackground
                    ? AppColors.of(context).warning.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: widget.isLightBackground
                    ? AppColors.of(context).warning
                    : Theme.of(context).colorScheme.onSurface,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'lbl_notifications'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: widget.isLightBackground
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_notifications_desc'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Benefit cards
            _BenefitRow(
              icon: Icons.wb_sunny_outlined,
              title: 'lbl_daily_verse'.tr,
              subtitle: 'msg_daily_verse_benefit'.tr,
              isLightBackground: widget.isLightBackground,
            ),
            const SizedBox(height: 16),
            _BenefitRow(
              icon: Icons.access_time,
              title: 'lbl_reading_reminder'.tr,
              subtitle: 'msg_reading_reminder_benefit'.tr,
              isLightBackground: widget.isLightBackground,
            ),
            const SizedBox(height: 16),
            _BenefitRow(
              icon: Icons.local_fire_department_outlined,
              title: 'lbl_streak_milestone'.tr,
              subtitle: 'msg_streak_milestone_benefit'.tr,
              isLightBackground: widget.isLightBackground,
            ),
            const SizedBox(height: 16),
            _BenefitRow(
              icon: Icons.mosque_outlined,
              title: 'lbl_friday_kahf'.tr,
              subtitle: 'msg_friday_kahf_benefit'.tr,
              isLightBackground: widget.isLightBackground,
            ),

            const Spacer(flex: 2),

            // Enable button
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: OnboardingPrimaryButton(
                text: _isLoading ? 'lbl_setting_up'.tr : 'lbl_enable_notifications'.tr,
                onPressed: _isLoading ? null : _enableNotifications,
                isLightBackground: widget.isLightBackground,
              ),
            ),
            const SizedBox(height: 12),

            // Skip button
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: OnboardingSecondaryButton(
                text: 'lbl_skip_for_now'.tr,
                onPressed: _isLoading ? null : _skip,
                isLightBackground: widget.isLightBackground,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLightBackground;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLightBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLightBackground
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLightBackground
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

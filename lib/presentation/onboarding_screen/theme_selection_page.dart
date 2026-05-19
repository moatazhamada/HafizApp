import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/analytics/analytics_properties.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class ThemeSelectionPage extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final String? themeMode;
  final bool isLightBackground;
  final ValueChanged<String> onThemeModeChanged;

  const ThemeSelectionPage({
    super.key,
    required this.onContinue,
    required this.onBack,
    this.themeMode,
    this.isLightBackground = false,
    required this.onThemeModeChanged,
  });

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final saved = PrefUtils().getThemeMode();
    _selected = (saved == 'light' || saved == 'dark') ? saved : 'system';
  }

  final List<_ThemeOption> _options = const [
    _ThemeOption(
      mode: 'light',
      icon: Icons.wb_sunny_rounded,
      labelKey: 'lbl_light_mode',
      descKey: 'msg_light_mode_desc',
    ),
    _ThemeOption(
      mode: 'dark',
      icon: Icons.nights_stay_rounded,
      labelKey: 'lbl_dark_mode',
      descKey: 'msg_dark_mode_desc',
    ),
    _ThemeOption(
      mode: 'system',
      icon: Icons.brightness_auto_rounded,
      labelKey: 'lbl_system_mode',
      descKey: 'msg_system_mode_desc',
    ),
  ];

  void _select(String mode) {
    setState(() => _selected = mode);
    widget.onThemeModeChanged(mode);
    // Apply theme immediately so the user sees the change right away
    context.read<ThemeBloc>().add(ChangeThemeModeEvent(mode));
    PrefUtils().setThemeMode(mode);
  }

  void _continue() {
    final mode = _selected;
    context.read<ThemeBloc>().add(ChangeThemeModeEvent(mode));
    final brightness = switch (mode) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    sl<AnalyticsService>().logThemeChange(brightness == Brightness.dark);
    unawaited(
      sl<AnalyticsService>().setUserProperty(
        name: AnalyticsProperties.themeMode,
        value: widget.themeMode ?? 'system',
      ),
    );
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
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.palette_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'lbl_choose_theme'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_theme_desc'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Theme options
            ..._options.map((option) {
              final isSelected = _selected == option.mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OnboardingSelectionCard(
                  isSelected: isSelected,
                  onTap: () => _select(option.mode),
                  isLightBackground: widget.isLightBackground,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          option.icon,
                          color: widget.isLightBackground
                              ? option.iconColor(context)
                              : Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.labelKey.tr,
                              style: TextStyle(
                                color: widget.isLightBackground
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.descKey.tr,
                              style: TextStyle(
                                color: widget.isLightBackground
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: widget.isLightBackground
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(flex: 2),

            // Continue button
            OnboardingPrimaryButton(
              text: 'lbl_continue'.tr,
              onPressed: _continue,
              isLightBackground: widget.isLightBackground,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final String mode;
  final IconData icon;
  final String labelKey;
  final String descKey;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.labelKey,
    required this.descKey,
  });
}

extension on _ThemeOption {
  Color iconColor(BuildContext context) => switch (mode) {
    'light' => AppColors.of(context).warning,
    'dark' => Theme.of(context).colorScheme.primary,
    _ => AppColors.of(context).statBookmark,
  };
}

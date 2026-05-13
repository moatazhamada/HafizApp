import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/utils/rtl_utils.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class LanguageSelectionPage extends StatelessWidget {
  final VoidCallback onContinue;
  final String? themeMode;
  final bool isLightBackground;

  const LanguageSelectionPage({
    super.key,
    required this.onContinue,
    this.themeMode,
    this.isLightBackground = false,
  });

  void _selectLanguage(BuildContext context, String code) {
    Locale newLocale;
    if (code == 'system') {
      final systemLoc = WidgetsBinding.instance.platformDispatcher.locale;
      newLocale = (systemLoc.languageCode == 'en')
          ? const Locale('en', 'US')
          : const Locale('ar', 'EG');
    } else {
      newLocale = Locale(code, code == 'en' ? 'US' : 'EG');
    }
    LocaleController.setLocale(newLocale);
    PrefUtils().setLocaleCode(code);
    onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLarge = MediaQuery.of(context).size.width > 900;

    return OnboardingScaffold(
      themeMode: themeMode,
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
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.language_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'lbl_choose_language'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_language_desc'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Language options
            _LanguageCard(
              code: 'EN',
              label: 'English',
              sublabel: 'English',
              isLightBackground: isLightBackground,
              onTap: () => _selectLanguage(context, 'en'),
            ),
            const SizedBox(height: 16),
            _LanguageCard(
              code: 'ع',
              label: 'العربية',
              sublabel: 'Arabic',
              isLightBackground: isLightBackground,
              onTap: () => _selectLanguage(context, 'ar'),
            ),
            const SizedBox(height: 16),
            _LanguageCard(
              code: null,
              label: 'lbl_system_default'.tr,
              sublabel: 'System',
              isSystem: true,
              isLightBackground: isLightBackground,
              onTap: () => _selectLanguage(context, 'system'),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String? code;
  final String label;
  final String sublabel;
  final bool isSystem;
  final bool isLightBackground;
  final VoidCallback onTap;

  const _LanguageCard({
    this.code,
    required this.label,
    required this.sublabel,
    this.isSystem = false,
    this.isLightBackground = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingSelectionCard(
      isSelected: false,
      onTap: onTap,
      isLightBackground: isLightBackground,
      child: Row(
        children: [
          if (isSystem)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language_rounded,
                color: isLightBackground ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                code!,
                style: TextStyle(
                  color: isLightBackground ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isLightBackground ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isSystem)
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: isLightBackground
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            rtlForwardArrowIos(context),
            color: isLightBackground
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}

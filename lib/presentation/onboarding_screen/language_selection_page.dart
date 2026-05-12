import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/i18n/locale_controller.dart';

class LanguageSelectionPage extends StatelessWidget {
  final VoidCallback onContinue;

  const LanguageSelectionPage({super.key, required this.onContinue});

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.8),
              colorScheme.primary,
              theme.brightness == Brightness.dark
                  ? Colors.black
                  : const Color(0xFF00332C),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth > 900;

              Widget content = Padding(
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'lbl_choose_language'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'msg_language_desc'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Language options
                    _LanguageCard(
                      flag: '🇬🇧',
                      label: 'English',
                      sublabel: 'English',
                      onTap: () => _selectLanguage(context, 'en'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageCard(
                      flag: '🇸🇦',
                      label: 'العربية',
                      sublabel: 'Arabic',
                      onTap: () => _selectLanguage(context, 'ar'),
                    ),
                    const SizedBox(height: 16),
                    _LanguageCard(
                      flag: '🌐',
                      label: 'lbl_system_default'.tr,
                      sublabel: 'System',
                      isSystem: true,
                      onTap: () => _selectLanguage(context, 'system'),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              );

              if (isLarge) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: content,
                  ),
                );
              }
              return content;
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String label;
  final String sublabel;
  final bool isSystem;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.label,
    required this.sublabel,
    this.isSystem = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isSystem)
                      Text(
                        sublabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

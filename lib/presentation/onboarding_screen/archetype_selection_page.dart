import 'package:flutter/material.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/app_export.dart';
import '../../core/models/user_archetype.dart';
import '../../injection_container.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class ArchetypeSelectionPage extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final String? themeMode;
  final bool isLightBackground;

  const ArchetypeSelectionPage({
    super.key,
    required this.onContinue,
    required this.onBack,
    this.themeMode,
    this.isLightBackground = false,
  });

  @override
  State<ArchetypeSelectionPage> createState() => _ArchetypeSelectionPageState();
}

class _ArchetypeSelectionPageState extends State<ArchetypeSelectionPage> {
  UserArchetype? _selected;

  void _select(UserArchetype archetype) {
    setState(() => _selected = archetype);
  }

  void _continue() {
    final archetype = _selected ?? UserArchetype.reader;
    PrefUtils().setUserArchetype(archetype.name);
    PrefUtils().setSurfaceType(archetype.name);
    sl<AnalyticsService>().logArchetypeSelected(archetype.name);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLarge = MediaQuery.of(context).size.width > 900;

    return OnboardingScaffold(
      themeMode: widget.themeMode,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 64 : 24),
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Title
            Text(
              'lbl_how_use_app'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_archetype_desc'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Archetype cards
            Expanded(
              child: ListView.builder(
                itemCount: UserArchetype.all.length,
                itemBuilder: (context, index) {
                  final archetype = UserArchetype.all[index];
                  final isSelected = _selected == archetype;
                  final color = Color(archetype.colorValue);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OnboardingSelectionCard(
                      isSelected: isSelected,
                      onTap: () => _select(archetype),
                      isLightBackground: widget.isLightBackground,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              archetype.icon,
                              color: widget.isLightBackground
                                  ? Color(archetype.colorValue)
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  archetype.labelKey.tr,
                                  style: TextStyle(
                                    color: widget.isLightBackground
                                        ? Colors.black87
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  archetype.descriptionKey.tr,
                                  style: TextStyle(
                                    color: widget.isLightBackground
                                        ? Colors.black.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.7),
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
                                  ? Color(archetype.colorValue)
                                  : Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: OnboardingPrimaryButton(
                text: 'lbl_continue'.tr,
                onPressed: _continue,
                isLightBackground: widget.isLightBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

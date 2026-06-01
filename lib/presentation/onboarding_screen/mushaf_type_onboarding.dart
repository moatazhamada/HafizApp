import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_types.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class MushafTypeOnboarding extends StatefulWidget {
  final bool fromSettings;

  const MushafTypeOnboarding({super.key, this.fromSettings = false});

  @override
  State<MushafTypeOnboarding> createState() => _MushafTypeOnboardingState();
}

class _MushafTypeOnboardingState extends State<MushafTypeOnboarding> {
  MushafType? _selected;

  @override
  void initState() {
    super.initState();
    final saved = PrefUtils().getMushafType();
    _selected = MushafType.fromString(saved);
  }

  void _select(MushafType type) {
    setState(() => _selected = type);
    PrefUtils().setMushafType(type.name);
  }

  void _continue() {
    _finish();
  }

  void _finish() {
    if (widget.fromSettings) {
      NavigatorService.goBack();
    } else {
      PrefUtils().setOnboardingCompleted(true);
      NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSettings = widget.fromSettings;

    Widget bodyContent = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final isLarge = maxWidth > 900;
          final isMedium = maxWidth > 600;

          final crossAxisCount = isLarge ? 4 : (isMedium ? 3 : 2);
          final childAspectRatio = isLarge ? 1.0 : 0.85;
          final horizontalPadding = isLarge
              ? 32.0
              : (isMedium ? 24.0 : 16.0);
          final iconSize = isLarge ? 72.0 : 56.0;
          final iconRadius = isLarge ? 16.0 : 12.0;
          final iconIconSize = isLarge ? 36.0 : 28.0;
          final spacing = isLarge ? 20.0 : 12.0;

          return Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'lbl_select_mushaf_type'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 64 : 32),
                child: Text(
                  'msg_mushaf_type_desc'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: MushafType.all.length,
                  itemBuilder: (context, index) {
                    final type = MushafType.all[index];
                    final isSelected = _selected == type;

                    return OnboardingSelectionCard(
                      isSelected: isSelected,
                      onTap: () => _select(type),
                      isLightBackground: isSettings
                          ? theme.brightness == Brightness.light
                          : false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(iconRadius),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: theme.colorScheme.onSurface,
                              size: iconIconSize,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            type.label.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.descriptionKey.tr,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: OnboardingPrimaryButton(
                  text: isSettings ? 'lbl_save'.tr : 'lbl_next'.tr,
                  onPressed: _continue,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (isSettings) {
      return Scaffold(
        appBar: AppBar(
          title: Text('lbl_mushaf_type'.tr),
        ),
        body: bodyContent,
      );
    } else {
      return OnboardingScaffold(
        maxContentWidth: 1000,
        child: bodyContent,
      );
    }
  }
}

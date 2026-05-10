import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/mushaf_types.dart';

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

  void _skip() {
    PrefUtils().setMushafType(MushafType.madani.name);
    if (widget.fromSettings) {
      NavigatorService.goBack();
    } else {
      PrefUtils().setOnboardingCompleted(true);
      NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen);
    }
  }

  void _continue() {
    if (_selected == null) {
      PrefUtils().setMushafType(MushafType.madani.name);
    }
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'lbl_select_mushaf_type'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'msg_mushaf_type_desc'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: MushafType.all.length,
                itemBuilder: (context, index) {
                  final type = MushafType.all[index];
                  final isSelected = _selected == type;
                  final color = Color(type.colorValue);

                  return GestureDetector(
                    onTap: () => _select(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : theme.dividerColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              type.label.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.descriptionKey.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(onPressed: _skip, child: Text('lbl_skip'.tr)),
                  const Spacer(),
                  FilledButton(
                    onPressed: _continue,
                    child: Text('lbl_next'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

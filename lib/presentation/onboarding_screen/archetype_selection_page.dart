import 'package:flutter/material.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/app_export.dart';
import '../../core/models/user_archetype.dart';
import '../../injection_container.dart';


class ArchetypeSelectionPage extends StatefulWidget {
  final VoidCallback onContinue;

  const ArchetypeSelectionPage({super.key, required this.onContinue});

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
                        color: Colors.white.withValues(alpha: 0.7),
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
                            child: Material(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => _select(archetype),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
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
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              archetype.labelKey.tr,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              archetype.descriptionKey.tr,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.65,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Continue button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: SizedBox(
                        width: double.maxFinite,
                        child: FilledButton(
                          onPressed: _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'lbl_continue'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
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

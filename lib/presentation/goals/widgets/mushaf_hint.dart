import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class MushafHint extends StatelessWidget {
  final String? mushafLabelKey;
  final ThemeData theme;
  const MushafHint({super.key, this.mushafLabelKey, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: colors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'goals_mushaf_hint'
                  .tr
                  .replaceAll('{mushaf}', mushafLabelKey?.tr ?? ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primaryDark.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';

class DuaKhatmCard extends StatelessWidget {
  final int completions;

  const DuaKhatmCard({this.completions = 0, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => NavigatorService.pushNamed(AppRoutes.duaKhatm),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_dua_khatm'.tr,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (completions > 0)
                      Text(
                        'msg_khatmah_count'
                            .tr
                            .replaceAll('{count}', '$completions'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                rtlChevron(context),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

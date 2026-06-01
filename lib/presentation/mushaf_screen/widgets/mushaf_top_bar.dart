import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';

class MushafTopBar extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onBackPressed;
  final VoidCallback onTypePressed;
  final VoidCallback onJumpPressed;

  const MushafTopBar({
    super.key,
    required this.colors,
    required this.onBackPressed,
    required this.onTypePressed,
    required this.onJumpPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.mushafPageBg,
            colors.mushafPageBg.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Semantics(
                button: true,
                label: 'lbl_back'.tr,
                child: IconButton(
                  icon: Icon(rtlBackArrow(context), color: colors.textPrimary),
                  onPressed: onBackPressed,
                  tooltip: 'lbl_back'.tr,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'lbl_select_mushaf_type'.tr,
                child: IconButton(
                  icon: Icon(Icons.menu_book, color: colors.textPrimary),
                  onPressed: onTypePressed,
                  tooltip: 'lbl_select_mushaf_type'.tr,
                ),
              ),
              Semantics(
                button: true,
                label: 'lbl_jump_to_page'.tr,
                child: IconButton(
                  icon: Icon(Icons.search, color: colors.textPrimary),
                  onPressed: onJumpPressed,
                  tooltip: 'lbl_jump_to_page'.tr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

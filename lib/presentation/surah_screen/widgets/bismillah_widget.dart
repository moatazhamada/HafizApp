import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class BismillahWidget extends StatelessWidget {
  final int surahId;

  const BismillahWidget({super.key, required this.surahId});

  @override
  Widget build(BuildContext context) {
    if (surahId == 1 || surahId == 9) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'lbl_bismillah'.tr,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(
          '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
          '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
          '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).bismillahColor,
          ),
        ),
      ),
    );
  }
}

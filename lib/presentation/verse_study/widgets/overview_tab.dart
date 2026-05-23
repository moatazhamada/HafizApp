import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'section_card.dart';
import '../bloc/verse_study_bloc.dart';
import '../verse_study_utils.dart';

class OverviewTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const OverviewTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.arabicText.isNotEmpty) ...[
            SectionCard(
              title: 'lbl_arabic'.tr,
              icon: Icons.format_quote,
              color: AppColors.of(context).statBookmark,
              child: Semantics(
                label: 'lbl_quran_text'.tr,
                textDirection: TextDirection.rtl,
                child: SelectableText(
                  state.arabicText,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: PrefUtils().getQuranFontSize(),
                    height: 2.0,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (state.translation.isNotEmpty) ...[
            SectionCard(
              title: 'lbl_translation'.tr,
              icon: Icons.translate,
              color: Theme.of(context).colorScheme.primary,
              child: SelectableText(stripHtml(state.translation)),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'section_card.dart';
import '../bloc/verse_study_bloc.dart';
import '../verse_study_utils.dart';

class TranslationTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const TranslationTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'lbl_translation'.tr,
            icon: Icons.translate,
            color: Theme.of(context).colorScheme.primary,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'lbl_select_translation'.tr,
              onPressed: () => showSourceSelector(
                context,
                title: 'lbl_select_translation'.tr,
                options: translationOptions,
                selectedId: state.selectedTranslationId,
                onSelected: (id) => context.read<VerseStudyBloc>().add(
                  ChangeTranslationSource(id: id, verseKey: state.verseKey!),
                ),
              ),
            ),
            child:
                state.translation.isNotEmpty
                    ? SelectableText(stripHtml(state.translation))
                    : Text('lbl_loading'.tr),
          ),
        ],
      ),
    );
  }
}

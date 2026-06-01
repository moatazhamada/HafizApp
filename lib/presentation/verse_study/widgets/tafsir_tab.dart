import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'section_card.dart';
import '../bloc/verse_study_bloc.dart';
import '../verse_study_utils.dart';

class TafsirTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const TafsirTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: tafsirTitleForId(state.selectedTafsirId),
            icon: Icons.menu_book,
            color: Theme.of(context).colorScheme.tertiary,
            trailing: IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'lbl_select_tafsir'.tr,
              onPressed: () => showSourceSelector(
                context,
                title: 'lbl_select_tafsir'.tr,
                options: tafsirOptions(context),
                selectedId: state.selectedTafsirId,
                onSelected: (id) => context.read<VerseStudyBloc>().add(
                  ChangeTafsirSource(id: id, verseKey: state.verseKey!),
                ),
              ),
            ),
            child:
                state.tafsir.isNotEmpty
                    ? SelectableText(stripHtml(state.tafsir))
                    : Text('lbl_loading'.tr),
          ),
        ],
      ),
    );
  }
}

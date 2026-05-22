import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_bloc.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_event.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_state.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_section_header.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_summary_card.dart';

class HifzListView extends StatelessWidget {
  final HifzLoaded state;
  final Widget Function(HifzEntry entry, bool isDue, bool compact)
      entryBuilder;

  const HifzListView({
    super.key,
    required this.state,
    required this.entryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HifzBloc>().add(LoadHifzEntries());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          HifzSummaryCard(state: state),
          const SizedBox(height: 20),
          if (state.dueToday.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_due_today'.tr,
              count: state.dueToday.length,
            ),
            const SizedBox(height: 8),
            ...state.dueToday.map((e) => entryBuilder(e, true, false)),
            const SizedBox(height: 20),
          ],
          if (state.newLessons.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_new_lessons'.tr,
              count: state.newLessons.length,
            ),
            const SizedBox(height: 8),
            ...state.newLessons.map((e) => entryBuilder(e, false, false)),
            const SizedBox(height: 20),
          ],
          if (state.recent.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_recent_lessons'.tr,
              count: state.recent.length,
            ),
            const SizedBox(height: 8),
            ...state.recent.map((e) => entryBuilder(e, false, false)),
            const SizedBox(height: 20),
          ],
          if (state.solid.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_solid'.tr,
              count: state.solid.length,
            ),
            const SizedBox(height: 8),
            ...state.solid.map((e) => entryBuilder(e, false, true)),
            const SizedBox(height: 20),
          ],
          if (state.mastered.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_mastered'.tr,
              count: state.mastered.length,
            ),
            const SizedBox(height: 8),
            ...state.mastered.map((e) => entryBuilder(e, false, true)),
            const SizedBox(height: 20),
          ],
          if (state.weak.isNotEmpty) ...[
            HifzSectionHeader(
              title: 'lbl_weak'.tr,
              count: state.weak.length,
            ),
            const SizedBox(height: 8),
            ...state.weak.map((e) => entryBuilder(e, false, false)),
          ],
        ],
      ),
    );
  }
}

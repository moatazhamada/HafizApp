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
  final Widget Function(HifzEntry entry, bool isDue, bool compact) entryBuilder;

  const HifzListView({
    super.key,
    required this.state,
    required this.entryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Flatten sections into a single list for lazy building.
    final items = <_HifzListItem>[];
    items.add(const _HifzListItem.summary());

    void addSection(String title, List<HifzEntry> entries, bool isDue) {
      if (entries.isNotEmpty) {
        items.add(_HifzListItem.header(title, entries.length));
        for (final e in entries) {
          items.add(_HifzListItem.entry(e, isDue));
        }
      }
    }

    addSection('lbl_due_today'.tr, state.dueToday, true);
    addSection('lbl_new_lessons'.tr, state.newLessons, false);
    addSection('lbl_recent_lessons'.tr, state.recent, false);
    addSection('lbl_solid'.tr, state.solid, false);
    addSection('lbl_mastered'.tr, state.mastered, false);
    addSection('lbl_weak'.tr, state.weak, false);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HifzBloc>().add(LoadHifzEntries());
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return switch (item.type) {
            _HifzItemType.summary => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: HifzSummaryCard(state: state),
              ),
            _HifzItemType.header => Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: HifzSectionHeader(
                  title: item.title!,
                  count: item.count!,
                ),
              ),
            _HifzItemType.entry => entryBuilder(item.entry!, item.isDue, false),
          };
        },
      ),
    );
  }
}

enum _HifzItemType { summary, header, entry }

class _HifzListItem {
  final _HifzItemType type;
  final String? title;
  final int? count;
  final HifzEntry? entry;
  final bool isDue;

  const _HifzListItem.summary()
      : type = _HifzItemType.summary,
        title = null,
        count = null,
        entry = null,
        isDue = false;

  const _HifzListItem.header(this.title, this.count)
      : type = _HifzItemType.header,
        entry = null,
        isDue = false;

  const _HifzListItem.entry(this.entry, this.isDue)
      : type = _HifzItemType.entry,
        title = null,
        count = null;
}

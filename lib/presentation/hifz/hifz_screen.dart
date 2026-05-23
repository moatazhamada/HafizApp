import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/domain/entities/hifz_entry.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_bloc.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_event.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_state.dart';
import 'package:hafiz_app/widgets/loading_indicator.dart';
import 'package:hafiz_app/core/utils/bottom_sheet_utils.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_empty_state.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_error_view.dart';
import 'package:hafiz_app/presentation/hifz/widgets/hifz_list_view.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({super.key});

  static Widget builder(BuildContext context) {
    return _HifzScreenLoader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_my_hifz'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'lbl_help'.tr,
            onPressed: () {
              unawaited(
                sl<AnalyticsService>().logHelpOpened(feature: 'hifz'),
              );
              _showHelpSheet(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddEntrySheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<HifzBloc, HifzState>(
        listener: (context, state) {
          if (state is HifzActionError) {
            SnackBarHelper.show(context, message: state.message, type: SnackBarType.error);
          }
        },
        child: BlocBuilder<HifzBloc, HifzState>(
          buildWhen: (previous, current) =>
              current is! HifzActionLoading ||
              previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            if (state is HifzLoading || state is HifzActionLoading) {
              return const LoadingIndicator();
            }
            if (state is HifzError) {
              return HifzErrorView(message: state.message);
            }
            if (state is HifzLoaded) {
              if (state.entries.isEmpty) {
                return HifzEmptyState(onAddPressed: () => _showAddEntrySheet(context));
              }
              return HifzListView(
                state: state,
                entryBuilder: (entry, isDue, compact) => _HifzEntryCard(
                  entry: entry,
                  isDue: isDue,
                  compact: compact,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static void _showHelpSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.6,
      minSize: 0.4,
      maxSize: 0.8,
      builder: (ctx, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'hifz_help_title'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'hifz_help_desc'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('lbl_got_it'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showAddEntrySheet(BuildContext context) {
    final bloc = context.read<HifzBloc>();
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.7,
      minSize: 0.5,
      maxSize: 0.9,
      builder: (context, scrollController) => BlocProvider.value(
        value: bloc,
        child: _AddEntrySheet(scrollController: scrollController!),
      ),
    );
  }

  static void _showReviewDialog(
    BuildContext context, {
    required String entryId,
    required String surahName,
    required String rangeLabel,
    required List<ReviewLog> history,
  }) {
    final bloc = context.read<HifzBloc>();
    final scores = [
      (label: 'btn_perfect'.tr, score: 100, color: Colors.green),
      (label: 'btn_good'.tr, score: 85, color: Colors.lightGreen),
      (label: 'btn_okay'.tr, score: 70, color: Colors.orange),
      (label: 'btn_hard'.tr, score: 55, color: Colors.deepOrange),
      (label: 'btn_forgot'.tr, score: 20, color: Colors.red),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('dlg_review_title'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$surahName ($rangeLabel)',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...scores.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: s.color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      bloc.add(LogHifzReview(
                        entryId: entryId,
                        score: s.score,
                        scoreLabel: s.label,
                      ));
                    },
                    child: Text(s.label),
                  ),
                ),
              )),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'lbl_review_history'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...history.take(5).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(h.date), style: const TextStyle(fontSize: 12)),
                      Text(h.scoreLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('lbl_cancel'.tr),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day}/${d.month}';
  }
}

class _HifzScreenLoader extends StatefulWidget {
  @override
  State<_HifzScreenLoader> createState() => _HifzScreenLoaderState();
}

class _HifzScreenLoaderState extends State<_HifzScreenLoader> {
  HifzBloc? _bloc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createBloc();
  }

  void _createBloc() {
    setState(() {
      _error = null;
    });
    try {
      final bloc = sl<HifzBloc>()..add(LoadHifzEntries());
      setState(() {
        _bloc = bloc;
      });
    } catch (e, s) {
      Logger.error('Failed to create HifzBloc: $e\n$s', feature: 'Hifz');
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('lbl_my_hifz'.tr)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'msg_operation_failed'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: _createBloc,
                  child: Text('lbl_retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: bloc,
      child: const HifzScreen(),
    );
  }
}

class _HifzEntryCard extends StatelessWidget {
  final HifzEntry entry;
  final bool isDue;
  final bool compact;

  const _HifzEntryCard({required this.entry, this.isDue = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == entry.surahId,
      orElse: () => Surah(entry.surahId, '', ''),
    );
    final statusColor = _statusColor(context);
    final daysUntil = entry.daysUntilNextReview(DateTime.now());
    final isOverdue = daysUntil < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: compact ? 0 : 1,
      color: isDue ? statusColor.withValues(alpha: 0.08) : AppColors.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isDue
            ? BorderSide(color: statusColor.withValues(alpha: 0.3))
            : BorderSide(color: AppColors.of(context).mushafPageBorder.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            '${entry.surahId}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
        title: Text(
          '${surah.nameArabic} ${entry.rangeLabel}',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 14 : 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.title != null && entry.title!.isNotEmpty)
              Text(entry.title!, style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary)),
            Text(
              _subtitleText(context, daysUntil, isOverdue),
              style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
            ),
            if (entry.reviewStreak > 2)
              Text(
                '🔥 ${'lbl_streak'.tr}: ${entry.reviewStreak}',
                style: TextStyle(fontSize: 11, color: AppColors.of(context).inProgressStatus, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.of(context).textSecondary, size: 20),
          onSelected: (value) {
            if (value == 'review') {
              HifzScreen._showReviewDialog(
                context,
                entryId: entry.id,
                surahName: surah.nameArabic,
                rangeLabel: entry.rangeLabel,
                history: entry.reviewHistory,
              );
            } else if (value == 'delete') {
              _confirmDelete(context, entry.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'review',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: AppColors.of(context).memorizedStatus),
                  const SizedBox(width: 8),
                  Text('lbl_log_review'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text('lbl_delete'.tr, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => HifzScreen._showReviewDialog(
          context,
          entryId: entry.id,
          surahName: surah.nameArabic,
          rangeLabel: entry.rangeLabel,
          history: entry.reviewHistory,
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    final colors = AppColors.of(context);
    switch (entry.status) {
      case HifzStatus.newLesson:
        return colors.inProgressStatus;
      case HifzStatus.recent:
        return colors.primary;
      case HifzStatus.solid:
        return colors.memorizedStatus;
      case HifzStatus.mastered:
        return colors.memorizedStatus;
      case HifzStatus.weak:
        return colors.needsReviewStatus;
    }
  }

  String _subtitleText(BuildContext context, int daysUntil, bool isOverdue) {
    if (isOverdue) {
      return '${'lbl_overdue'.tr}: ${-daysUntil} ${'lbl_days'.tr}';
    }
    if (daysUntil == 0) return 'lbl_due_today'.tr;
    if (daysUntil == 1) return 'lbl_due_tomorrow'.tr;
    return '${'lbl_next_review'.tr}: $daysUntil ${'lbl_days'.tr}';
  }

  void _confirmDelete(BuildContext context, String entryId) {
    final bloc = context.read<HifzBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('lbl_delete'.tr),
        content: Text('msg_confirm_delete_hifz'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('lbl_cancel'.tr)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(DeleteHifzEntry(entryId));
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('lbl_delete'.tr),
          ),
        ],
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  final ScrollController scrollController;

  const _AddEntrySheet({required this.scrollController});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  Surah? _selectedSurah;
  int _startVerse = 1;
  int _endVerse = 1;
  int _verseCount = 1;
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onSurahChanged(Surah? surah) {
    if (surah == null) return;
    setState(() {
      _selectedSurah = surah;
      _verseCount = MushafPageIndex.getVerseCount(surah.id);
      _startVerse = 1;
      _endVerse = _verseCount.clamp(1, _verseCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahs = QuranIndex.quranSurahs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'lbl_add_hifz_entry'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              InputDecorator(
                decoration: InputDecoration(labelText: 'lbl_select_surah'.tr, border: const OutlineInputBorder()),
                child: DropdownButton<Surah>(
                  value: _selectedSurah,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: Text('lbl_select_surah'.tr),
                  items: surahs.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s.id}. ${s.nameArabic}', textDirection: TextDirection.rtl),
                  )).toList(),
                  onChanged: _onSurahChanged,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedSurah != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_startVerse',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'lbl_start_verse'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final val = int.tryParse(v) ?? 1;
                          setState(() {
                            _startVerse = val.clamp(1, _verseCount);
                            if (_endVerse < _startVerse) _endVerse = _startVerse;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_endVerse',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'lbl_end_verse'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final val = int.tryParse(v) ?? _verseCount;
                          setState(() {
                            _endVerse = val.clamp(_startVerse, _verseCount);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${'lbl_total_verses'.tr}: $_verseCount',
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).notStartedStatus),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'lbl_optional_title'.tr,
                    hintText: 'lbl_optional_title_hint'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: Text('lbl_save'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool get _canSubmit => _selectedSurah != null && _startVerse >= 1 && _endVerse >= _startVerse;

  void _submit() {
    if (!_canSubmit) return;
    context.read<HifzBloc>().add(AddHifzEntry(
      surahId: _selectedSurah!.id,
      startVerse: _startVerse,
      endVerse: _endVerse,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }
}

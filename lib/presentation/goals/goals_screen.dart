import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart' as di;
import 'bloc/goals_bloc.dart';
import '../auth/bloc/qf_auth_bloc.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<GoalsBloc>()..add(LoadTodaysPlan()),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('goals_title'.tr)),
      body: MultiBlocListener(
        listeners: [
          BlocListener<GoalsBloc, GoalsState>(
            listener: (context, state) {
              if (state is GoalsActionError) {
                SnackBarHelper.show(
                  context,
                  message: state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
          BlocListener<QfAuthBloc, QfAuthState>(
            listener: (context, authState) {
              if (authState is QfAuthAuthenticated) {
                context.read<GoalsBloc>().add(LoadTodaysPlan());
              }
            },
          ),
        ],
        child: BlocBuilder<QfAuthBloc, QfAuthState>(
          builder: (context, authState) {
            final isAuth = authState is QfAuthAuthenticated;

            if (!isAuth) {
              return _AuthPrompt(theme: theme);
            }

            return BlocBuilder<GoalsBloc, GoalsState>(
              builder: (context, state) {
                if (state is GoalsLoading || state is GoalsActionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is GoalsError) {
                  return _ErrorView(theme: theme, message: state.message);
                }

                if (state is GoalsActionError) {
                  return _ErrorView(theme: theme, message: state.message);
                }

                if (state is GoalsLoaded) {
                  if (state.items.isEmpty) {
                    return _EmptyPlanView(theme: theme);
                  }
                  return _PlanList(items: state.items, theme: theme);
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}

class _AuthPrompt extends StatelessWidget {
  final ThemeData theme;
  const _AuthPrompt({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'goals_auth_required'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'goals_auth_hint'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  context.read<QfAuthBloc>().add(QfAuthLoginRequested()),
              icon: const Icon(Icons.login),
              label: Text('msg_qf_login'.tr),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final String message;
  const _ErrorView({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'goals_error_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => context.read<GoalsBloc>().add(LoadTodaysPlan()),
              child: Text('lbl_retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanView extends StatelessWidget {
  final ThemeData theme;
  const _EmptyPlanView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'goals_no_plan'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'goals_no_plan_hint'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  final List<PlanItem> items;
  final ThemeData theme;
  const _PlanList({required this.items, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GoalsBloc>().add(LoadTodaysPlan());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryHeader(items: items, colors: colors, theme: theme),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _PlanItemCard(
              item: item,
              isDark: isDark,
              colors: colors,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final List<PlanItem> items;
  final AppColors colors;
  final ThemeData theme;
  const _SummaryHeader({
    required this.items,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final completed = items.where((i) {
      final p = i.progress ?? 0;
      final d = i.duration ?? 0;
      return d > 0 && p >= d;
    }).length;

    return Card(
      elevation: 0,
      color: colors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lbl_today_reading'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'goals_items_count'.tr.replaceAll(
                      '{count}',
                      '${items.length}',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primaryDark.withValues(alpha: 0.7),
                    ),
                  ),
                  if (completed > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$completed ${'goals_completed'.tr.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.of(context).success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  final PlanItem item;
  final bool isDark;
  final AppColors colors;
  final ThemeData theme;
  const _PlanItemCard({
    required this.item,
    required this.isDark,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = item.progress ?? 0;
    final duration = item.duration ?? 0;
    final progressFrac = duration > 0
        ? (progress / duration).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = duration > 0 && progress >= duration;

    final label = item.name ?? _categoryLabel(item.category);
    final progressText = duration > 0
        ? 'goals_progress_label'.tr
              .replaceAll('{done}', '$progress')
              .replaceAll('{total}', '$duration')
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isComplete
              ? AppColors.of(context).memorizedStatus.withValues(alpha: 0.3)
              : colors.mushafPageBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.of(context).memorizedStatus.withValues(alpha: 0.1)
                        : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.task_alt_rounded,
                    color: isComplete ? AppColors.of(context).memorizedStatus : colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (item.amount != null)
                        Text(
                          '${item.amount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary),
                  onSelected: (value) => _onMenuSelected(value, context),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'update',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text('lbl_edit'.tr),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text('lbl_delete'.tr,
                              style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (progressText != null)
                  Text(
                    progressText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isComplete ? AppColors.of(context).memorizedStatus : colors.primary,
                    ),
                  ),
              ],
            ),
            if (duration > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressFrac,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? AppColors.of(context).memorizedStatus : colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isComplete ? 'goals_completed'.tr : 'goals_in_progress'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isComplete ? AppColors.of(context).memorizedStatus : colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(String value, BuildContext context) {
    if (value == 'update') {
      _showUpdateDialog(context);
    } else if (value == 'delete') {
      _showDeleteConfirm(context);
    }
  }

  void _showUpdateDialog(BuildContext context) {
    final durationCtrl = TextEditingController(
      text: item.duration?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('goals_edit_title'.tr),
        content: TextField(
          controller: durationCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'goals_duration_label'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('lbl_cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newDuration = int.tryParse(durationCtrl.text);
              if (newDuration != null) {
                context.read<GoalsBloc>().add(UpdateGoalEvent(
                  id: item.id,
                  type: item.type,
                  amount: item.amount,
                  category: item.category,
                  duration: newDuration,
                ));
              }
            },
            child: Text('lbl_save'.tr),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('goals_delete_title'.tr),
        content: Text('goals_delete_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('lbl_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GoalsBloc>().add(DeleteGoalEvent(
                id: item.id,
                category: item.category,
              ));
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text('lbl_delete'.tr),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    if (category.isEmpty) return 'goals_title'.tr;
    return category
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

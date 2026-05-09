import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/theme/app_colors.dart';
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
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('goals_title'.tr)),
      body: BlocBuilder<QfAuthBloc, QfAuthState>(
        builder: (context, authState) {
          final isAuth = authState is QfAuthAuthenticated;

          if (!isAuth) {
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
                      'msg_login_to_sync'.tr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<QfAuthBloc>()
                          .add(QfAuthLoginRequested()),
                      icon: const Icon(Icons.login),
                      label: Text('msg_qf_login'.tr),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<GoalsBloc, GoalsState>(
            builder: (context, state) {
              if (state is GoalsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GoalsError) {
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
                          state.message.tr,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.tonal(
                          onPressed: () =>
                              context.read<GoalsBloc>().add(LoadTodaysPlan()),
                          child: Text('lbl_retry'.tr),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is GoalsLoaded) {
                if (state.items.isEmpty) {
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
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'goals_no_plan_hint'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<GoalsBloc>().add(LoadTodaysPlan());
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryHeader(items: state.items, colors: colors, isDark: isDark),
                      const SizedBox(height: 12),
                      ...state.items.map(
                        (item) => _PlanItemCard(item: item, isDark: isDark, colors: colors),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final List<PlanItem> items;
  final AppColors colors;
  final bool isDark;

  const _SummaryHeader({
    required this.items,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'goals_items_count'
                        .tr
                        .replaceAll('{count}', '${items.length}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.primaryDark.withValues(alpha: 0.7),
                    ),
                  ),
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

  const _PlanItemCard({
    required this.item,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item.progress ?? 0;
    final duration = item.duration ?? 0;
    final progressFrac =
        duration > 0 ? (progress / duration).clamp(0.0, 1.0) : 0.0;

    final label = item.name ?? item.category;
    final amountStr =
        item.amount != null ? '${item.amount}' : '';
    final subtitle = [
      item.type.isNotEmpty ? item.type : null,
      amountStr.isNotEmpty ? amountStr : null,
    ].whereType<String>().join(' \u2022 ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.mushafPageBorder.withValues(alpha: 0.2)),
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
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    color: colors.primary,
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
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (duration > 0)
                  Text(
                    '$progress / $duration',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
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
                  backgroundColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressFrac >= 1.0
                        ? Colors.green
                        : colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

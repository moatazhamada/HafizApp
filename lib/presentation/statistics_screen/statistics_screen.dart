import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/quran_index/quran_surah.dart';
import '../bookmarks/bloc/bookmark_bloc.dart';
import '../recitation_error/bloc/recitation_error_bloc.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('stats_title'.tr)),
      body: MultiBlocBuilder(
        blocs: [
          context.read<BookmarkBloc>(),
          context.read<RecitationErrorBloc>(),
        ],
        builders: (context) {
          int bookmarkCount = 0;
          int practiceCount = 0;

          final bookmarkState = context.read<BookmarkBloc>().state;
          if (bookmarkState is BookmarkLoaded) {
            bookmarkCount = bookmarkState.bookmarks.length;
          }

          final errorState = context.read<RecitationErrorBloc>().state;
          if (errorState is RecitationErrorLoaded) {
            practiceCount = errorState.errors.length;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                context,
                theme,
                icon: Icons.bookmark_rounded,
                label: 'stats_bookmarks'.tr,
                value: bookmarkCount,
                color: Colors.teal,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                theme,
                icon: Icons.playlist_add_check_rounded,
                label: 'stats_practice_verses'.tr,
                value: practiceCount,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                theme,
                icon: Icons.menu_book_rounded,
                label: 'stats_surahs_completed'.tr,
                value: 0,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              if (bookmarkCount == 0 && practiceCount == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'stats_no_activity'.tr,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
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

typedef MultiBlocWidgetBuilder = Widget Function(BuildContext context);

class MultiBlocBuilder extends StatelessWidget {
  final List<StateStreamable> blocs;
  final MultiBlocWidgetBuilder builders;

  const MultiBlocBuilder({
    super.key,
    required this.blocs,
    required this.builders,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = builders(context);
    for (final bloc in blocs) {
      result = BlocBuilder(
        bloc: bloc,
        builder: (context, _) => builders(context),
      );
    }
    return result;
  }
}

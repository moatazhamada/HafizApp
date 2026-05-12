import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../data/datasource/qf_post/qf_post_remote_data_source.dart';
import '../../injection_container.dart';
import '../home_screen/widgets/staggered_list_item.dart';

class QuranReflectFeedScreen extends StatefulWidget {
  const QuranReflectFeedScreen({super.key});

  @override
  State<QuranReflectFeedScreen> createState() => _QuranReflectFeedScreenState();
}

class _QuranReflectFeedScreenState extends State<QuranReflectFeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final ds = sl<QfPostRemoteDataSource>();
      final posts = await ds.getFeed(first: 30);
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      Logger.warning('Failed to load Quran Reflect feed: $e',
          feature: 'QuranReflect');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('lbl_quran_reflect_feed'.tr),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _buildBody(theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'msg_feed_load_error'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadFeed,
              child: Text('lbl_retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'msg_no_reflections'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'msg_be_first_reflection'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return StaggeredListItem(
          index: index,
          child: _ReflectionCard(post: post),
        );
      },
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const _ReflectionCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final text = post['text'] as String? ?? '';
    final verseKey = post['verseKey'] as String?;
    final author = post['user']?['name'] as String? ?? 'Anonymous';
    final createdAt = post['createdAt'] as String?;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (verseKey != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  verseKey,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'lbl_today'.tr;
      if (diff.inDays == 1) return 'lbl_yesterday'.tr;
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}

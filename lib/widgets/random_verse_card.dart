import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/data/datasource/random_verse/random_verse_remote_data_source.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class RandomVerseCard extends StatefulWidget {
  const RandomVerseCard({super.key});

  @override
  State<RandomVerseCard> createState() => _RandomVerseCardState();
}

class _RandomVerseCardState extends State<RandomVerseCard>
    with AutomaticKeepAliveClientMixin {
  RandomVerseData? _data;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    try {
      final ds = sl<RandomVerseRemoteDataSource>();
      final verse = await ds.fetchRandomVerse();
      if (mounted) {
        setState(() {
          _data = verse;
          _loading = false;
        });
      }
    } catch (e) {
      Logger.warning('RandomVerseCard load error: $e', feature: 'RandomVerse');
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
    super.build(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Card(
        elevation: 1,
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null || _data == null) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Verse of the Moment',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _data!.arabicText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'NotoNaskhArabic',
                height: 1.8,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '— ${_data!.verseKey}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_data!.englishText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _data!.englishText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _data = null;
                  _error = null;
                });
                _loadVerse();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('New Verse', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

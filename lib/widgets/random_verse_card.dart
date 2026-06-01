import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_spacing.dart';
import 'package:hafiz_app/data/datasource/random_verse/random_verse_remote_data_source.dart';
import 'package:hafiz_app/data/datasource/verse_media/verse_media_remote_data_source.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/localization/app_localization.dart';

class RandomVerseCard extends StatefulWidget {
  const RandomVerseCard({super.key});

  @override
  State<RandomVerseCard> createState() => _RandomVerseCardState();
}

class _RandomVerseCardState extends State<RandomVerseCard>
    with AutomaticKeepAliveClientMixin {
  RandomVerseData? _data;
  List<VerseMediaItem> _media = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVerse(daily: true);
  }

  Future<void> _loadVerse({bool daily = false}) async {
    try {
      final ds = sl<RandomVerseRemoteDataSource>();
      var verse = await ds.fetchRandomVerse();
      // Fallback to local assets when the API is unreachable
      verse ??= await ds.fetchLocalRandomVerse(daily: daily);
      if (mounted) {
        setState(() {
          _data = verse;
          _error = null;
          _loading = false;
        });
      }
      // Fetch verse media after verse is loaded
      if (verse != null) {
        await _loadMedia(verse.verseKey);
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

  Future<void> _loadMedia(String verseKey) async {
    try {
      final ds = sl<VerseMediaRemoteDataSource>();
      final media = await ds.getVerseMedia(verseKey);
      if (mounted) {
        setState(() => _media = media);
      }
    } catch (e) {
      Logger.warning('Verse media load error: $e', feature: 'RandomVerse');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = AppColors.of(context);

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

    if (_error != null || _data == null) {
      return _buildErrorCard(context);
    }

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
                  'lbl_verse_of_day'.tr,
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '— ${_data!.verseKey}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (_media.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildMediaCarousel(),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _data = null;
                  _error = null;
                });
                _loadVerse(daily: false);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('lbl_new_verse'.tr, style: const TextStyle(fontSize: 12)),
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

  Widget _buildErrorCard(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      color: colors.errorBackground.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.needsReviewStatus.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: colors.needsReviewStatus,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'lbl_verse_of_day'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.needsReviewStatus,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'msg_verse_of_day_error'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _data = null;
                  _error = null;
                });
                _loadVerse(daily: true);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('lbl_try_again'.tr, style: const TextStyle(fontSize: 12)),
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

  Widget _buildMediaCarousel() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _media.length,
        itemBuilder: (context, index) {
          final item = _media[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.url,
                width: 160,
                height: 120,
                fit: BoxFit.cover,
                memCacheWidth: 320,
                memCacheHeight: 240,
                maxWidthDiskCache: 320,
                maxHeightDiskCache: 240,
                placeholder: (context, url) => Container(
                  width: 160,
                  height: 120,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 160,
                  height: 120,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/mushaf/mushaf_cache_manager.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

const _invertFilter = ColorFilter.matrix([
  -1,  0,  0,  0, 255,
   0, -1,  0,  0, 255,
   0,  0, -1,  0, 255,
   0,  0,  0,  1,   0,
]);

class MushafPageWidget extends StatefulWidget {
  final int pageNumber;
  final MushafType mushafType;
  final ValueChanged<bool>? onZoomChanged;

  /// Called when the user starts or ends any interaction (pan/scale).
  /// This fires earlier than [onZoomChanged] and is used to disable
  /// PageView scrolling before the gesture arena resolves.
  final ValueChanged<bool>? onInteractionStart;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = MushafType.madani,
    this.onZoomChanged,
    this.onInteractionStart,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  final ValueNotifier<bool> _zoomNotifier = ValueNotifier<bool>(false);

  /// Number of active pointers currently on this page.
  /// Used to detect multi-touch before the gesture arena resolves.
  int _pointerCount = 0;

  /// Whether we have already notified the parent that interaction started.
  bool _notifiedInteraction = false;

  late AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (_zoomNotifier.value != zoomed) {
      _zoomNotifier.value = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  // ─── Pointer counting for early PageView lock ────────────────────

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount >= 2 && !_notifiedInteraction) {
      _notifiedInteraction = true;
      widget.onInteractionStart?.call(true);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerCount--;
    if (_pointerCount < 2 && _notifiedInteraction) {
      _notifiedInteraction = false;
      widget.onInteractionStart?.call(false);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerCount--;
    if (_pointerCount < 2 && _notifiedInteraction) {
      _notifiedInteraction = false;
      widget.onInteractionStart?.call(false);
    }
  }

  // ─── Double-tap to zoom ──────────────────────────────────────────

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final targetScale = currentScale > 1.05 ? 1.0 : 2.5;

    final viewport = context.size ?? MediaQuery.sizeOf(context);
    final begin = _transformController.value;
    // Build the zoom-to-center matrix directly to avoid deprecated API.
    // Equivalent to: translate(cx, cy) * scale(s) * translate(-cx, -cy)
    final cx = viewport.width / 2;
    final cy = viewport.height / 2;
    final end = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, cx * (1 - targetScale))
      ..setEntry(1, 3, cy * (1 - targetScale));

    _zoomAnimation?.removeListener(_onZoomAnimationTick);
    _zoomAnimation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _zoomAnimation!.addListener(_onZoomAnimationTick);
    _zoomAnimationController
      ..reset()
      ..forward();
  }

  void _onZoomAnimationTick() {
    if (_zoomAnimation != null) {
      _transformController.value = _zoomAnimation!.value;
    }
  }

  @override
  void dispose() {
    _zoomAnimation?.removeListener(_onZoomAnimationTick);
    _zoomAnimationController.dispose();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _zoomNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = widget.mushafType.pageImageUrl(widget.pageNumber);

    final imageWidget = _MushafImage(
      url: url,
      mushafType: widget.mushafType,
      pageNumber: widget.pageNumber,
      isDark: isDark,
      colors: colors,
    );

    final madaniPage = widget.mushafType.totalPages == MushafPageIndex.totalPages
        ? widget.pageNumber
        : (widget.pageNumber / widget.mushafType.totalPages * MushafPageIndex.totalPages)
            .round()
            .clamp(1, MushafPageIndex.totalPages);
    final surahId = MushafPageIndex.getSurahForPage(madaniPage);
    final surah = surahId >= 1 && surahId <= 114
        ? QuranIndex.quranSurahs[surahId - 1]
        : null;
    final surahName = surah != null
        ? (Localizations.localeOf(context).languageCode == 'ar'
            ? surah.nameArabic
            : surah.nameEnglish)
        : '';

    return Semantics(
      label: 'lbl_semantics_mushaf_page'
          .tr
          .replaceAll('{page}', '${widget.pageNumber}')
          .replaceAll('{surah}', surahName),
      textDirection: TextDirection.rtl,
      image: true,
      child: Container(
        color: colors.mushafPageBg,
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: ValueListenableBuilder<bool>(
            valueListenable: _zoomNotifier,
            builder: (context, isZoomed, child) => GestureDetector(
              onDoubleTap: _handleDoubleTap,
              behavior: HitTestBehavior.translucent,
              child: InteractiveViewer(
                transformationController: _transformController,
                panEnabled: isZoomed,
                minScale: 0.5,
                maxScale: 4.0,
                child: child!,
              ),
            ),
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}

/// Isolated image widget that does not rebuild when zoom state changes.
class _MushafImage extends StatelessWidget {
  final String url;
  final MushafType mushafType;
  final int pageNumber;
  final bool isDark;
  final AppColors colors;

  const _MushafImage({
    required this.url,
    required this.mushafType,
    required this.pageNumber,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      cacheManager: MushafCacheManager.instance,
      cacheKey: MushafCacheManager.cacheKey(mushafType.name, pageNumber),
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isDark
              ? colors.mushafTextPrimary.withValues(alpha: 0.4)
              : colors.mushafPageBorder.withValues(alpha: 0.4),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: colors.mushafPageBg,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colors.textSecondary,
            size: 48,
          ),
        ),
      ),
    );

    if (!isDark) return image;

    return ColorFiltered(
      colorFilter: _invertFilter,
      child: image,
    );
  }
}

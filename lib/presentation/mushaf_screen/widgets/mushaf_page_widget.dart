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

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = MushafType.madani,
    this.onZoomChanged,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  final TransformationController _transformController =
      TransformationController();
  final ValueNotifier<bool> _zoomNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (_zoomNotifier.value != zoomed) {
      _zoomNotifier.value = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  @override
  void dispose() {
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
        child: ValueListenableBuilder<bool>(
          valueListenable: _zoomNotifier,
          builder: (context, isZoomed, child) => InteractiveViewer(
            transformationController: _transformController,
            panEnabled: isZoomed,
            minScale: 0.5,
            maxScale: 4.0,
            child: child!,
          ),
          child: imageWidget,
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

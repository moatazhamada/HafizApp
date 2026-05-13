import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';

const _invertMatrix = <double>[
  -1,
  0,
  0,
  0,
  255,
  0,
  -1,
  0,
  0,
  255,
  0,
  0,
  -1,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
];

class MushafPageWidget extends StatefulWidget {
  final int pageNumber;
  final MushafType mushafType;
  final Widget? fallback;
  final ValueChanged<bool>? onZoomChanged;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = MushafType.madani,
    this.fallback,
    this.onZoomChanged,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  final TransformationController _transformController =
      TransformationController();
  bool _isZoomedIn = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (_isZoomedIn != zoomed) {
      _isZoomedIn = zoomed;
      widget.onZoomChanged?.call(zoomed);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = widget.mushafType.pageImageUrl(widget.pageNumber);

    final imageWidget = isDark
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(_invertMatrix),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.mushafTextPrimary.withValues(alpha: 0.4),
                ),
              ),
              errorWidget: (context, url, error) =>
                  widget.fallback ??
                  Container(
                    color: colors.mushafPageBg,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
            ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.mushafPageBorder.withValues(alpha: 0.4),
              ),
            ),
            errorWidget: (context, url, error) =>
                widget.fallback ??
                Container(
                  color: colors.mushafPageBg,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.textSecondary,
                      size: 32,
                    ),
                  ),
                ),
          );

    return Semantics(
      label: 'Mushaf page ${widget.pageNumber}',
      image: true,
      child: Container(
        color: colors.mushafPageBg,
        child: InteractiveViewer(
          transformationController: _transformController,
          panEnabled: _isZoomedIn,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageWidget,
        ),
      ),
    );
  }
}

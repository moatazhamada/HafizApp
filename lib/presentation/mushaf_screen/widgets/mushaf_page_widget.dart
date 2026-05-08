import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/mushaf/mushaf_rendering_config.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';

class MushafPageWidget extends StatelessWidget {
  final int pageNumber;
  final String mushafType;
  final int imageWidth;
  final Widget? fallback;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = 'madani',
    this.imageWidth = 1024,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (!MushafRenderingConfig.hasPageImages(mushafType)) {
      return fallback ??
          Container(
            color: colors.mushafPageBg,
            child: Center(
              child: Text(
                '$pageNumber',
                style: TextStyle(color: colors.textHint),
              ),
            ),
          );
    }

    final url = MushafRenderingConfig.pageImageUrl(
      pageNumber,
      mushafType: mushafType,
      width: imageWidth,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.mushafPageBg,
        border: Border.symmetric(
          vertical: BorderSide(
            color: colors.mushafPageBorder.withValues(alpha: 0.15),
            width: 6,
          ),
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.mushafPageBorder.withValues(alpha: 0.4),
          ),
        ),
        errorWidget: (context, url, error) =>
            fallback ??
            Container(
              color: colors.mushafPageBg,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.textHint,
                  size: 32,
                ),
              ),
            ),
      ),
    );
  }
}

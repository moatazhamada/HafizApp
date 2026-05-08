import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';

class MushafPageWidget extends StatelessWidget {
  final int pageNumber;
  final MushafType mushafType;
  final Widget? fallback;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = MushafType.madani,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final url = mushafType.pageImageUrl(pageNumber);

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

import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class SurahListItem extends StatelessWidget {
  final int surahId;
  final String nameEnglish;
  final String nameArabic;

  const SurahListItem({
    super.key,
    required this.surahId,
    required this.nameEnglish,
    required this.nameArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.ltr,
            // Force LTR order regardless of app locale
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Card(
                color: const Color(0xFF87D1A4),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 8.0,
                    bottom: 8.0,
                    right: 16.0,
                  ),
                  child: Text(
                    '$surahId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nameEnglish,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Hero(
                  tag: 'surah-title-$surahId',
                  child: Text(
                    nameArabic,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(
                        PrefUtils().getIsDarkMode() == true
                            ? 0xFFD9D8D8
                            : 0xFF076C58,
                      ),
                      fontFamily: "Amiri",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          surahId < 114
              ? Container(
                  height: 1.adaptSize,
                  width: double.infinity,
                  color: const Color(0xFFD9D8D8),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

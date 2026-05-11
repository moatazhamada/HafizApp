import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/core/utils/string_utils.dart';
import 'package:hafiz_app/domain/repository/tafsir_repository.dart';
import 'package:hafiz_app/injection_container.dart';

void showTafsirSheet(
  BuildContext context, {
  required int surahId,
  required String surahName,
  required int verseNumber,
}) {
  unawaited(
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => FutureBuilder(
          future: sl<TafsirRepository>().getTafsir(surahId, verseNumber),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${'lbl_tafsir'.tr}: $surahName - '
                          '${'lbl_ayah'.tr} ${verseNumber.toLocalizedNumber(context)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'lbl_close'.tr,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError || snapshot.data?.isLeft() == true
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'msg_tafsir_error'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: snapshot.data!.fold(
                            (failure) => Text(
                              'msg_tafsir_error'.tr,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            (tafsir) => Text(
                              stripHtmlTags(tafsir.text),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

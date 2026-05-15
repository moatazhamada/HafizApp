import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/core/utils/string_utils.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
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
          future: sl<TafsirRepository>().getTafsir(surahId, verseNumber).then((result) {
            // Track as reading session (estimated 30s for tafsir)
            sl<KhatmahRepository>().reportReadingSession(
              ReadingSession(
                surahId: surahId,
                startVerse: verseNumber,
                endVerse: verseNumber,
                durationSeconds: 30,
                readAt: DateTime.now(),
              ),
            );
            return result;
          }),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'msg_tafsir_error'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                            (tafsir) => Text(
                              stripHtmlTags(tafsir.text),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface,
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

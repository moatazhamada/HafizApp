import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/number_converter.dart';
import 'package:hafiz_app/core/utils/string_utils.dart';
import 'package:hafiz_app/domain/entities/reading_session.dart';
import 'package:hafiz_app/domain/repository/khatmah_repository.dart';
import 'package:hafiz_app/domain/repository/tafsir_repository.dart';
import 'package:hafiz_app/core/analytics/analytics_service.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/core/utils/bottom_sheet_utils.dart';
import 'package:hafiz_app/widgets/loading_indicator.dart';

void showTafsirSheet(
  BuildContext context, {
  required int surahId,
  required String surahName,
  required int verseNumber,
}) {
  unawaited(
    sl<AnalyticsService>().logTafsirOpened(
      surahId: surahId,
      verseNumber: verseNumber,
    ),
  );
  unawaited(
    showAppBottomSheet(
      context: context,
      useDraggable: true,
      initialSize: 0.5,
      minSize: 0.3,
      maxSize: 0.8,
      builder: (sheetContext, scrollController) => _TafsirContent(
        surahId: surahId,
        surahName: surahName,
        verseNumber: verseNumber,
        scrollController: scrollController!,
      ),
    ),
  );
}

class _TafsirContent extends StatefulWidget {
  final int surahId;
  final String surahName;
  final int verseNumber;
  final ScrollController scrollController;

  const _TafsirContent({
    required this.surahId,
    required this.surahName,
    required this.verseNumber,
    required this.scrollController,
  });

  @override
  State<_TafsirContent> createState() => _TafsirContentState();
}

class _TafsirContentState extends State<_TafsirContent> {
  late final Future<dynamic> _tafsirFuture;

  @override
  void initState() {
    super.initState();
    _tafsirFuture = sl<TafsirRepository>()
        .getTafsir(widget.surahId, widget.verseNumber)
        .then((result) {
      sl<KhatmahRepository>().reportReadingSession(
        ReadingSession(
          surahId: widget.surahId,
          startVerse: widget.verseNumber,
          endVerse: widget.verseNumber,
          durationSeconds: 30,
          readAt: DateTime.now(),
        ),
      );
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _tafsirFuture,
      builder: (context, snapshot) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'lbl_tafsir'.tr}: ${widget.surahName} - '
                      '${'lbl_ayah'.tr} ${widget.verseNumber.toLocalizedNumber(context)}',
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
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
                  ? const Center(child: LoadingIndicator())
                  : snapshot.hasError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.38),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'msg_tafsir_error'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16),
                          child: snapshot.data!.fold(
                            (failure) => Text(
                              'msg_tafsir_error'.tr,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            (tafsir) => Text(
                              stripHtmlTags(tafsir.text),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

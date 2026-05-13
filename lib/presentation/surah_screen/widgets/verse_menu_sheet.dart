import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/share_as_image.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/surah_screen/widgets/verse_image_card.dart';
import 'package:hafiz_app/widgets/verse_share_sheet.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

void showVerseMenu(
  BuildContext context, {
  required Verse verse,
  required int surahId,
  required String surahNameEnglish,
  required bool isBookmarked,
  required bool isError,
  required VoidCallback onVerifyRecitation,
  required VoidCallback onOpenTafsir,
  required VoidCallback onReadThisAyah,
  required VoidCallback onStartFromHere,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          Semantics(
            button: true,
            label: isBookmarked
                ? 'lbl_remove_bookmark'.tr
                : 'lbl_add_bookmark'.tr,
            child: ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                isBookmarked
                    ? 'lbl_remove_bookmark'.tr
                    : 'lbl_add_bookmark'.tr,
              ),
              onTap: () {
                Navigator.pop(context);
                if (isBookmarked) {
                  HapticFeedback.lightImpact();
                  context.read<BookmarkBloc>().add(
                    RemoveBookmarkEvent(surahId, verse.verseNumber),
                  );
                } else {
                  HapticFeedback.lightImpact();
                  context.read<BookmarkBloc>().add(
                    AddBookmarkEvent(
                      BookmarkModel(
                        surahId: surahId,
                        surahName: surahNameEnglish,
                        verseNumber: verse.verseNumber,
                        createdAt: DateTime.now(),
                      ),
                    ),
                  );
                }
                _triggerBookmarkSync(context);
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_read_this_ayah'.tr,
            child: ListTile(
              leading: Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('lbl_read_this_ayah'.tr),
              onTap: () {
                Navigator.pop(context);
                onReadThisAyah();
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_start_from_here'.tr,
            child: ListTile(
              leading: Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('lbl_start_from_here'.tr),
              onTap: () {
                Navigator.pop(context);
                onStartFromHere();
              },
            ),
          ),
          Semantics(
            button: true,
            label: isError
                ? 'msg_unmark_practice'.tr
                : 'msg_mark_practice'.tr,
            child: ListTile(
              leading: Icon(
                isError ? Icons.playlist_remove : Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                isError ? 'msg_unmark_practice'.tr : 'msg_mark_practice'.tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isError) {
                  context.read<RecitationErrorBloc>().add(
                    RemoveRecitationErrorEvent(surahId, verse.verseNumber),
                  );
                } else {
                  context.read<RecitationErrorBloc>().add(
                    AddRecitationErrorEvent(
                      RecitationErrorModel(
                        surahId: surahId,
                        surahName: surahNameEnglish,
                        verseId: verse.verseNumber,
                        createdAt: DateTime.now(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_verify_recitation'.tr,
            child: ListTile(
              leading: Icon(
                Icons.mic,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: Text('lbl_verify_recitation'.tr),
              onTap: () {
                Navigator.pop(context);
                onVerifyRecitation();
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_share_verse'.tr,
            child: ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('lbl_share_verse'.tr),
              onTap: () {
                Navigator.pop(context);
                VerseShareSheet.show(
                  context: context,
                  verseText: verse.arabicText,
                  surahId: surahId,
                  verseNumber: verse.verseNumber,
                  surahName: surahNameEnglish,
                  translation: verse.translationText,
                );
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_share_as_image'.tr,
            child: ListTile(
              leading: Icon(
                Icons.image_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('lbl_share_as_image'.tr),
              onTap: () async {
                Navigator.pop(context);
                await _shareVerseAsImage(verse, surahNameEnglish);
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_tafsir'.tr,
            child: ListTile(
              leading: Icon(
                Icons.menu_book,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('lbl_tafsir'.tr),
              onTap: () {
                Navigator.pop(context);
                onOpenTafsir();
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'lbl_study'.tr,
            child: ListTile(
              leading: Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text('lbl_study'.tr),
              onTap: () {
                Navigator.pop(context);
                NavigatorService.pushNamed(
                  AppRoutes.verseStudyScreen,
                  arguments: {'verseKey': '$surahId:${verse.verseNumber}'},
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _shareVerseAsImage(Verse verse, String surahName) async {
  final rootContext = NavigatorService.navigatorKey.currentContext;
  if (rootContext == null) return;

  final navigator = Navigator.of(rootContext, rootNavigator: true);
  final scaffoldMessenger = ScaffoldMessenger.of(rootContext);

  unawaited(showDialog(
    context: rootContext,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  ));

  final key = GlobalKey();
  final overlay = Overlay.of(rootContext);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -9999,
      child: RepaintBoundary(
        key: key,
        child: VerseImageCard(
          arabicText: verse.arabicText,
          surahName: surahName,
          verseNumber: verse.verseNumber,
          translation: verse.translationText,
          width: 1080,
          height: 1350,
        ),
      ),
    ),
  );

  overlay.insert(entry);

  // Wait for the widget to render before capturing
  await Future.delayed(const Duration(milliseconds: 100));
  await WidgetsBinding.instance.endOfFrame;

  try {
    final path = await ShareAsImage.captureWidget(key);
    entry.remove();
    navigator.pop();
    await Share.shareXFiles([XFile(path)], text: 'Shared from Hafiz');
  } catch (e) {
    entry.remove();
    navigator.pop();
    Logger.error('Failed to share image: $e', feature: 'Sharing');
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('msg_operation_failed'.tr)),
    );
  }
}

void _triggerBookmarkSync(BuildContext context) {
  try {
    context.read<CloudSyncBloc>().add(SyncWithQfEvent());
  } catch (e) {
    Logger.warning('Bookmark sync trigger failed: \$e', feature: 'Bookmarks');
  }
}

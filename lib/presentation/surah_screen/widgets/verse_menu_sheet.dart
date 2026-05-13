import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/data/model/bookmark_model.dart';
import 'package:hafiz_app/data/model/recitation_error_model.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/widgets/verse_share_sheet.dart';

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
                );
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

void _triggerBookmarkSync(BuildContext context) {
  try {
    context.read<CloudSyncBloc>().add(SyncWithQfEvent());
  } catch (e) {
    Logger.warning('Bookmark sync trigger failed: \$e', feature: 'Bookmarks');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/core/utils/surah_name_formatter.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'audio_control_bar.dart';
import 'auto_scroll_controls.dart';

class SurahAppBar extends StatelessWidget {
  final bool isDark;
  final Surah? surah;
  final bool isAutoScrolling;
  final double autoScrollSpeed;
  final bool isListeningMode;
  final bool isHifzMode;
  final bool showTranslation;
  final int? highlightedVerse;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onShowAutoScrollSpeedDialog;
  final VoidCallback onToggleListeningMode;
  final VoidCallback onToggleHifzMode;
  final VoidCallback onToggleBookmark;
  final VoidCallback onToggleTranslation;
  final VoidCallback onNavigateToHelp;
  final void Function(int? startVerse) onNavigateToAudioPlayer;

  const SurahAppBar({
    required this.isDark,
    required this.surah,
    required this.isAutoScrolling,
    required this.autoScrollSpeed,
    required this.isListeningMode,
    required this.isHifzMode,
    required this.showTranslation,
    required this.highlightedVerse,
    required this.onToggleAutoScroll,
    required this.onShowAutoScrollSpeedDialog,
    required this.onToggleListeningMode,
    required this.onToggleHifzMode,
    required this.onToggleBookmark,
    required this.onToggleTranslation,
    required this.onNavigateToHelp,
    required this.onNavigateToAudioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.of(context).appBarBackground,
      leading: Semantics(
        button: true,
        label: 'lbl_back'.tr,
        child: IconButton(
          icon: Icon(rtlBackArrow(context), color: AppColors.of(context).onPrimary),
          onPressed: () => NavigatorService.goBack(),
          tooltip: 'lbl_back'.tr,
        ),
      ),
      actions: [
        AutoScrollControls(
          isAutoScrolling: isAutoScrolling,
          autoScrollSpeed: autoScrollSpeed,
          onToggle: onToggleAutoScroll,
          onShowSpeedDialog: onShowAutoScrollSpeedDialog,
        ),
        if (surah != null)
          AudioControlBar(
            isListeningMode: isListeningMode,
            onToggle: onToggleListeningMode,
          ),
        Semantics(
          button: true,
          label: 'lbl_more_options'.tr,
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.of(context).onPrimary,
            ),
            onSelected: (value) {
              switch (value) {
                case 'audio':
                  if (surah == null) return;
                  onNavigateToAudioPlayer(highlightedVerse);
                  break;
                case 'help':
                  onNavigateToHelp();
                  break;
                case 'hifz':
                  onToggleHifzMode();
                  break;
                case 'bookmark':
                  onToggleBookmark();
                  break;
                case 'translation':
                  onToggleTranslation();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'audio',
                child: Row(
                  children: [
                    const Icon(Icons.headphones),
                    const SizedBox(width: 12),
                    Text('lbl_audio_player'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    const Icon(Icons.help_outline),
                    const SizedBox(width: 12),
                    Text('lbl_help'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hifz',
                child: Row(
                  children: [
                    Icon(isHifzMode ? Icons.visibility : Icons.visibility_off),
                    const SizedBox(width: 12),
                    Text(
                      isHifzMode ? 'lbl_exit_hifz_mode'.tr : 'lbl_hifz_mode'.tr,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bookmark',
                child: Builder(
                  builder: (context) {
                    final state = context.read<BookmarkBloc>().state;
                    final isSurahBookmarked =
                        state is BookmarkLoaded &&
                        state.bookmarks.any(
                          (b) => b.surahId == surah?.id && b.verseNumber == 1,
                        );
                    return Row(
                      children: [
                        Icon(
                          isSurahBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isSurahBookmarked
                              ? 'lbl_remove_surah_bookmark'.tr
                              : 'lbl_add_surah_bookmark'.tr,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (Localizations.localeOf(context).languageCode != 'ar')
                PopupMenuItem(
                  value: 'translation',
                  child: Row(
                    children: [
                      Icon(
                        showTranslation
                            ? Icons.text_fields
                            : Icons.text_fields_outlined,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        showTranslation
                            ? 'lbl_hide_translation'.tr
                            : 'lbl_show_translation'.tr,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          end: 16,
          bottom: 16,
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            header: true,
            child: Text(
              surah?.localizedName(context) ?? '',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).onPrimary,
                fontFamily: 'NotoNaskhArabic',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              right: -55,
              bottom: -10,
              child: ExcludeSemantics(
                child: CustomImageView(
                  fit: BoxFit.cover,
                  imagePath: ImageConstant.imgQuranOnboarding,
                  height: 150.v,
                  width: 150.h,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.of(context).appBarGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

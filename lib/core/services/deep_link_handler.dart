import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/core/utils/navigator_service.dart';
import 'package:hafiz_app/routes/app_routes.dart';

class DeepLinkHandler {
  StreamSubscription<Uri?>? _widgetClickSub;

  Future<void> initialize() async {
    // Handle the case where the app was cold-started via a widget click.
    // The widgetClicked stream event would have fired before this listener
    // was registered, so we check the initial launch URI.
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    _widgetClickSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'hafiz' || uri.host != 'verse') return;

    final segments = uri.pathSegments;
    if (segments.length < 2) return;

    final chapterId = int.tryParse(segments[0]);
    final verseNumber = int.tryParse(segments[1]);
    if (chapterId == null || verseNumber == null) return;

    final surah = QuranIndex.quranSurahs.firstWhere(
      (s) => s.id == chapterId,
      orElse: () => Surah(chapterId, 'Surah $chapterId', ''),
    );

    Logger.info(
      'Deep link: surah $chapterId, verse $verseNumber',
      feature: 'DeepLink',
    );

    NavigatorService.pushNamed(
      AppRoutes.surahPage,
      arguments: {'surah': surah, 'verseIndex': verseNumber - 1},
    );
  }

  void dispose() {
    _widgetClickSub?.cancel();
  }
}

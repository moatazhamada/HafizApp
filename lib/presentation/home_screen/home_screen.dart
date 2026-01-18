import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_route_observer.dart';
import 'package:hafiz_app/localization/app_localization.dart';
import '../../core/app_export.dart';

import '../../core/scroll/scroll_position_cubit.dart';
import '../../injection_container.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:hafiz_app/widgets/surah_list_item.dart';
import 'bloc/home_bloc.dart';
import '../../core/utils/number_converter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

void changeLocale(BuildContext context, Locale newLocale) {
  AppLocalization.of().setLocale(newLocale);
}

Locale getCurrentLocale() {
  return AppLocalization.of().getCurrentLocale();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final homeBloc = sl<HomeBloc>();
  final themeBloc = sl<ThemeBloc>();
  final scrollCubit = sl<ScrollPositionCubit>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = scrollCubit.getOffset('home');
      if (saved != null && _scrollController.hasClients) {
        try {
          _scrollController.jumpTo(saved);
        } catch (_) {}
      }
    });
    _scrollController.addListener(() {
      scrollCubit.saveOffset('home', _scrollController.offset);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      try {
        sl<AnalyticsRouteObserver>().subscribe(this, route);
      } catch (_) {}
    }
  }

  @override
  void didPopNext() {
    try {
      homeBloc.add(HomeShowLastSurahEvent());
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      sl<AnalyticsRouteObserver>().unsubscribe(this);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          // leading: Removed to allow title to center properly
          // leadingWidth: Removed
          title: Text(
            'app_name'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            ),
            onPressed: () {
              themeBloc.add(ToggleThemeEvent());
              sl<AnalyticsService>().logThemeChange(!isDarkMode);
            },
            tooltip: 'lbl_toggle_theme'.tr,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => NavigatorService.pushNamed(AppRoutes.searchPage),
              tooltip: 'lbl_search'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded),
              onPressed: () =>
                  NavigatorService.pushNamed(AppRoutes.bookmarksPage),
              tooltip: 'lbl_bookmarks'.tr,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mistakes':
                    NavigatorService.pushNamed(AppRoutes.recitationErrorsPage);
                    break;
                  case 'settings':
                    NavigatorService.pushNamed(AppRoutes.settingsScreen);
                    break;
                  case 'about':
                    NavigatorService.pushNamed(AppRoutes.aboutPage);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mistakes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_check,
                        color: theme.iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Text('lbl_practice_list'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Text('lbl_settings'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'about_title'.tr,
                      ), // Assuming 'about_title' key exists or use 'About'
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: BlocProvider<HomeBloc>(
          create: (context) => homeBloc,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  key: const PageStorageKey('home-scroll'),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      if ((state as UpdateLastReadSurah).surah != null)
                        _buildCardLastRead((state).surah, theme),

                      ListView.builder(
                        key: const PageStorageKey('home-list'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: QuranIndex.quranSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = QuranIndex.quranSurahs[index];

                          // Simple staggered animation logic
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuad,
                            // Delay based on index, capped to prevent long waits for bottom items
                            builder: (context, value, child) {
                              // Only animate the first 10 items to save performance/time
                              final shouldAnimate = index < 10;
                              final opacity = shouldAnimate ? value : 1.0;
                              final offset = shouldAnimate
                                  ? Offset(0, 50 * (1 - value))
                                  : Offset.zero;

                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: offset,
                                  child: child,
                                ),
                              );
                            },
                            child: InkWell(
                              onTap: () {
                                PrefUtils().saveLastReadSurah(surah);
                                homeBloc.add(HomeShowLastSurahEvent());
                                NavigatorService.pushNamed(
                                  AppRoutes.surahPage,
                                  arguments: surah,
                                );
                              },
                              child: SurahListItem(
                                surahId: surah.id,
                                nameEnglish: surah.nameEnglish,
                                nameArabic: surah.nameArabic,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardLastRead(Surah? lastReadSurah, ThemeData theme) {
    if (lastReadSurah == null) return const SizedBox.shrink();

    final int? lastVerseIndex = PrefUtils().getSurahVerseIndex(
      lastReadSurah.id,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF00332c), // Darker shade
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            const Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'lbl_last_read'.tr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (Localizations.localeOf(context).languageCode !=
                              'ar')
                            Text(
                              lastReadSurah.nameEnglish,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            lastReadSurah.nameArabic,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Amiri',
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (lastVerseIndex != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${"lbl_ayah".tr} ${(lastVerseIndex + 1).toLocalizedNumber(context)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final offset =
                            PrefUtils().getSurahOffset(lastReadSurah.id) ??
                            sl<ScrollPositionCubit>().getOffset(
                              'surah-${lastReadSurah.id}',
                            );

                        sl<AnalyticsService>().logContinueReading(
                          lastReadSurah.id,
                          offset ?? 0.0,
                        );

                        NavigatorService.pushNamed(
                          AppRoutes.surahPage,
                          arguments: {
                            'surah': lastReadSurah,
                            if (offset != null) 'offset': offset,
                            'resume': true,
                            if (lastVerseIndex != null)
                              'verseIndex': lastVerseIndex,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'lbl_continue'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

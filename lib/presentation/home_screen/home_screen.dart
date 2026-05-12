import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/juz_index.dart';

import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_route_observer.dart';

import '../../core/app_export.dart';


import '../../injection_container.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/offline_indicator.dart';
import 'bloc/home_bloc.dart';
import 'bloc/adaptive_home_bloc.dart';
import 'surfaces/reader_surface.dart';
import 'surfaces/student_surface.dart';
import 'surfaces/seeker_surface.dart';
import '../../core/models/surface_type.dart';
import '../../core/tracking/behavior_tracker.dart';
import 'widgets/surface_suggestion_banner.dart';
import 'widgets/adaptive_navigation.dart';
import 'widgets/animated_surface_switcher.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

void changeLocale(BuildContext context, Locale newLocale) {
  AppLocalization.of()?.setLocale(newLocale);
}

Locale getCurrentLocale() {
  return AppLocalization.of()?.getCurrentLocale() ?? const Locale('en');
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final homeBloc = sl<HomeBloc>();
  final themeBloc = sl<ThemeBloc>();
  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _showJuzSelector(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'lbl_juz_index'.tr,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final juz = JuzIndex.getJuz(index + 1);
                    if (juz == null) return const SizedBox.shrink();

                    return Semantics(
                      button: true,
                      label: JuzIndex.getJuzName(
                        juz.juzNumber,
                        isArabic: isArabic,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          final surah = QuranIndex.quranSurahs.firstWhere(
                            (s) => s.id == juz.startSurahId,
                          );
                          PrefUtils().saveLastReadSurah(surah);
                          homeBloc.add(HomeShowLastSurahEvent());
                          NavigatorService.pushNamed(
                            AppRoutes.surahPage,
                            arguments: {
                              'surah': surah,
                              'verseIndex': juz.startVerseNumber - 1,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.of(context).primary,
                                AppColors.of(
                                  context,
                                ).primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                juz.juzNumber.toString(),
                                style: AppTextStyles.numericLarge.copyWith(
                                  color: AppColors.of(context).onPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? juz.startSurahNameAr
                                    : juz.startSurahNameEn,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.of(context).onPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      title: Semantics(
        header: true,
        child: Text(
          'app_name'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      leading: Builder(
        builder: (scaffoldContext) => Semantics(
          button: true,
          label: 'lbl_open_nav_menu'.tr,
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            ),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            tooltip: 'lbl_open_nav_menu'.tr,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Semantics(
          button: true,
          label: 'lbl_toggle_theme'.tr,
          child: IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            ),
            onPressed: () {
              themeBloc.add(ToggleThemeEvent());
              sl<AnalyticsService>().logThemeChange(!isDarkMode);
            },
            tooltip: 'lbl_toggle_theme'.tr,
          ),
        ),
        Semantics(
          button: true,
          label: 'lbl_juz_index'.tr,
          child: IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            ),
            onPressed: () => _showJuzSelector(context),
            tooltip: 'lbl_juz_index'.tr,
          ),
        ),
        Semantics(
          button: true,
          label: 'lbl_search_tooltip'.tr,
          child: IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            ),
            onPressed: () =>
                NavigatorService.pushNamed(AppRoutes.searchPage),
            tooltip: 'lbl_search_tooltip'.tr,
          ),
        ),
      ],
    );

    final bodyContent = OfflineIndicator(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<AdaptiveHomeBloc>(
            create: (_) => AdaptiveHomeBloc()..add(AdaptiveHomeLoad()),
          ),
        ],
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            final lastReadSurah = homeState is UpdateLastReadSurah
                ? homeState.surah
                : null;
            final lastVerseIndex = lastReadSurah != null
                ? PrefUtils().getSurahVerseIndex(lastReadSurah.id)
                : null;

            return BlocBuilder<AdaptiveHomeBloc, AdaptiveHomeState>(
              builder: (context, adaptiveState) {
                final suggested = BehaviorTracker.suggestSurfaceType();
                final showBanner = suggested != null &&
                    suggested != adaptiveState.surfaceType.name &&
                    !BehaviorTracker.isSuggestionDismissed();

                return Column(
                  children: [
                    if (showBanner)
                      SurfaceSuggestionBanner(
                        suggestedSurface: suggested,
                        onDismiss: () {
                          BehaviorTracker.dismissSuggestion();
                          context
                              .read<AdaptiveHomeBloc>()
                              .add(AdaptiveHomeDismissSuggestion());
                        },
                        onAccept: () {
                          BehaviorTracker.dismissSuggestion();
                          context.read<AdaptiveHomeBloc>().add(
                                AdaptiveHomeChangeSurface(
                                  SurfaceType.fromString(suggested),
                                ),
                              );
                        },
                      ),
                    Expanded(
                      child: AnimatedSurfaceSwitcher(
                        surfaceType: adaptiveState.surfaceType,
                        child: switch (adaptiveState.surfaceType) {
                          SurfaceType.reader => ReaderSurface(
                              lastReadSurah: lastReadSurah,
                              lastVerseIndex: lastVerseIndex,
                            ),
                          SurfaceType.student => const StudentSurface(),
                          SurfaceType.seeker => const SeekerSurface(),
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > 900;

        if (isLarge) {
          return Scaffold(
            body: Row(
              children: [
                AdaptiveNavigationRail(
                  selectedIndex: -1,
                  onDestinationSelected: (index) =>
                      _onNavDestinationSelected(context, index),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      appBar,
                      Expanded(child: bodyContent),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: AdaptiveNavigationDrawer(
              onDestinationSelected: (index) =>
                  _onNavDestinationSelected(context, index),
            ),
            appBar: appBar,
            body: bodyContent,
          ),
        );
      },
    );
  }

  void _onNavDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        NavigatorService.pushNamed(AppRoutes.mushafScreen);
        break;
      case 1:
        NavigatorService.pushNamed(AppRoutes.goalsPage);
        break;
      case 2:
        NavigatorService.pushNamed(AppRoutes.bookmarksPage);
        break;
      case 3:
        NavigatorService.pushNamed(AppRoutes.recitationErrorsPage);
        break;
      case 4:
        NavigatorService.pushNamed(AppRoutes.recitationSessionsPage);
        break;
      case 5:
        NavigatorService.pushNamed(AppRoutes.memorizationPage);
        break;
      case 6:
        NavigatorService.pushNamed(AppRoutes.khatmahPage);
        break;
      case 7:
        NavigatorService.pushNamed(AppRoutes.statisticsScreen);
        break;
      case 8:
        NavigatorService.pushNamed(AppRoutes.settingsScreen);
        break;
      case 9:
        NavigatorService.pushNamed(AppRoutes.aboutPage);
        break;
    }
  }


}

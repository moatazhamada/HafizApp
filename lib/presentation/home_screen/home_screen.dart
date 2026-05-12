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

import '../auth/bloc/qf_auth_bloc.dart';

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

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _buildDrawer(context, theme),
        appBar: CustomAppBar(
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
        ),
        body: OfflineIndicator(
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
                    return switch (adaptiveState.surfaceType) {
                      SurfaceType.reader => ReaderSurface(
                          lastReadSurah: lastReadSurah,
                          lastVerseIndex: lastVerseIndex,
                        ),
                      SurfaceType.student => const StudentSurface(),
                      SurfaceType.seeker => const SeekerSurface(),
                    };
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return NavigationDrawer(
      selectedIndex: null,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
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
      },
      children: [
        _buildDrawerAuthHeader(context, theme),
        const Divider(height: 1),
        const SizedBox(height: 12),
        NavigationDrawerDestination(
          icon: const Icon(Icons.auto_stories_outlined),
          selectedIcon: const Icon(Icons.auto_stories_rounded),
          label: Text('lbl_mushaf'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.event_note_outlined),
          selectedIcon: const Icon(Icons.event_note_rounded),
          label: Text('goals_title'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.bookmark_outline_rounded),
          selectedIcon: const Icon(Icons.bookmark_rounded),
          label: Text('lbl_bookmarks'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.playlist_add_check_outlined),
          selectedIcon: const Icon(Icons.playlist_add_check_rounded),
          label: Text('lbl_practice_list'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history_rounded),
          label: Text('lbl_session_history'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.school_outlined),
          selectedIcon: const Icon(Icons.school_rounded),
          label: Text('lbl_memorization'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.auto_stories_outlined),
          selectedIcon: const Icon(Icons.auto_stories_rounded),
          label: Text('lbl_khatmah_tracker'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.trending_up_outlined),
          selectedIcon: const Icon(Icons.trending_up_rounded),
          label: Text('stats_title'.tr),
        ),
        const Divider(height: 24),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: Text('lbl_settings'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.info_outline_rounded),
          selectedIcon: const Icon(Icons.info_rounded),
          label: Text('about_title'.tr),
        ),
      ],
    );
  }

  Widget _buildDrawerAuthHeader(BuildContext context, ThemeData theme) {
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, state) {
        final Widget avatar;
        final String title;
        final String subtitle;

        if (state is QfAuthAuthenticated) {
          final initial = state.userId?.isNotEmpty == true
              ? state.userId![0].toUpperCase()
              : null;
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary,
            child: initial != null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: AppColors.of(context).onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : Icon(
                    Icons.account_circle,
                    color: AppColors.of(context).onPrimary,
                    size: 24,
                  ),
          );
          title = 'msg_qf_account'.tr;
          subtitle = 'msg_qf_logged_in'.tr;
        } else if (state is QfAuthLoading || state is QfAuthInitial) {
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        } else {
          // QfAuthUnauthenticated, QfAuthError, or any other state
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.account_circle_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        }

        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            NavigatorService.pushNamed(AppRoutes.cloudSyncPage);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}

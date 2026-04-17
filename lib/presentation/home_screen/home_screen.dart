import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/juz_index.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_route_observer.dart';

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
  final NetworkInfo _networkInfo = sl<NetworkInfo>();
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (mounted && _isOffline != !connected) {
        setState(() => _isOffline = !connected);
      }
    });
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

  Future<void> _checkConnectivity() async {
    final connected = await _networkInfo.isConnected();
    if (mounted) {
      setState(() => _isOffline = !connected);
    }
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
    _connectivitySub?.cancel();
    try {
      sl<AnalyticsRouteObserver>().unsubscribe(this);
    } catch (_) {}
    _scrollController.dispose();
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                                const Color(0xFF006754),
                                const Color(0xFF006754).withValues(alpha: 0.8),
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? juz.startSurahNameAr
                                    : juz.startSurahNameEn,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
              label: 'Open navigation menu',
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDarkMode ? Colors.white : theme.colorScheme.primary,
                ),
                onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                tooltip: 'Open navigation menu',
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
        body: BlocProvider<HomeBloc>.value(
          value: homeBloc,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return SizedBox(
                width: double.maxFinite,
                child: CustomScrollView(
                  controller: _scrollController,
                  key: const PageStorageKey('home-scroll'),
                  slivers: [
                    // Offline indicator banner
                    if (_isOffline)
                      SliverToBoxAdapter(
                        child: Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.orange.shade700,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'msg_offline'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (state is UpdateLastReadSurah && state.surah != null)
                      SliverToBoxAdapter(
                        child: _buildCardLastRead(state.surah, theme),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 20),
                      sliver: SliverList.builder(
                        key: const PageStorageKey('home-list'),
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
                            child: Semantics(
                              button: true,
                              label:
                                  '${surah.nameEnglish}, ${surah.nameArabic}, ${'lbl_surah'.tr} ${surah.id}',
                              child: InkWell(
                                onTap: () {
                                  PrefUtils().saveLastReadSurah(surah);
                                  homeBloc.add(HomeShowLastSurahEvent());
                                  final defaultView = PrefUtils()
                                      .getDefaultQuranView();
                                  if (defaultView == 'mushaf') {
                                    NavigatorService.pushNamed(
                                      AppRoutes.mushafScreen,
                                    );
                                  } else {
                                    NavigatorService.pushNamed(
                                      AppRoutes.surahPage,
                                      arguments: surah,
                                    );
                                  }
                                },
                                child: SurahListItem(
                                  surahId: surah.id,
                                  nameEnglish: surah.nameEnglish,
                                  nameArabic: surah.nameArabic,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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
            NavigatorService.pushNamed(AppRoutes.bookmarksPage);
            break;
          case 1:
            NavigatorService.pushNamed(AppRoutes.recitationErrorsPage);
            break;
          case 2:
            NavigatorService.pushNamed(AppRoutes.recitationSessionsPage);
            break;
          case 3:
            NavigatorService.pushNamed(AppRoutes.memorizationPage);
            break;
          case 4:
            NavigatorService.pushNamed(AppRoutes.khatmahPage);
            break;
          case 5:
            NavigatorService.pushNamed(AppRoutes.statisticsScreen);
            break;
          case 6:
            NavigatorService.pushNamed(AppRoutes.mushafScreen);
            break;
          case 7:
            NavigatorService.pushNamed(AppRoutes.settingsScreen);
            break;
          case 8:
            NavigatorService.pushNamed(AppRoutes.aboutPage);
            break;
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  'app_name'.tr[0],
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'app_name'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 12),
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
        NavigationDrawerDestination(
          icon: const Icon(Icons.auto_stories_outlined),
          selectedIcon: const Icon(Icons.auto_stories_rounded),
          label: Text('lbl_mushaf'.tr),
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

  Widget _buildCardLastRead(Surah? lastReadSurah, ThemeData theme) {
    if (lastReadSurah == null) return const SizedBox.shrink();

    final int? lastVerseIndex = PrefUtils().getSurahVerseIndex(
      lastReadSurah.id,
    );

    return Semantics(
      container: true,
      label:
          '${'lbl_last_read'.tr}: ${lastReadSurah.nameEnglish}${lastVerseIndex != null ? ', ${'lbl_ayah'.tr} ${lastVerseIndex + 1}' : ''}',
      child: Padding(
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
              // Decorative circle - exclude from semantics
              const Positioned(
                right: -30,
                bottom: -30,
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 150,
                      color: Colors.white,
                    ),
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
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.menu_book,
                            color: Colors.white70,
                            size: 16,
                          ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (Localizations.localeOf(
                                    context,
                                  ).languageCode !=
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
                                textDirection: TextDirection.rtl,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Amiri',
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
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

                    Semantics(
                      button: true,
                      label: 'lbl_continue'.tr,
                      child: SizedBox(
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

                            final defaultView = PrefUtils()
                                .getDefaultQuranView();
                            if (defaultView == 'mushaf') {
                              NavigatorService.pushNamed(
                                AppRoutes.mushafScreen,
                              );
                            } else {
                              NavigatorService.pushNamed(
                                AppRoutes.surahPage,
                                arguments: {
                                  'surah': lastReadSurah,
                                  'offset': ?offset,
                                  'resume': true,
                                  'verseIndex': ?lastVerseIndex,
                                },
                              );
                            }
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/quran_index/juz_index.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/analytics_helper.dart';
import '../../core/analytics/analytics_route_observer.dart';
import '../../core/ramadan/ramadan_theme.dart';

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
        } catch (e) {
          Logger.debug(
            'Error restoring scroll position',
            feature: 'HomeScreen',
            error: e,
          );
        }
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
      } catch (e) {
        Logger.debug(
          'Error subscribing to analytics',
          feature: 'HomeScreen',
          error: e,
        );
      }
    }
  }

  @override
  void didPopNext() {
    try {
      homeBloc.add(HomeShowLastSurahEvent());
    } catch (e) {
      Logger.debug(
        'Error showing last surah',
        feature: 'HomeScreen',
        error: e,
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    try {
      sl<AnalyticsRouteObserver>().unsubscribe(this);
    } catch (e) {
      Logger.debug(
        'Error unsubscribing from analytics',
        feature: 'HomeScreen',
        error: e,
      );
    }
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
                          // Track Juz navigation
                          unawaited(
                            sl<AnalyticsHelper>().logNavigationToJuz(
                              juz.juzNumber,
                            ),
                          );

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
          // leading: Removed to allow title to center properly
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
            builder: (context) => Semantics(
              button: true,
              label: 'Open navigation menu',
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDarkMode ? Colors.white : theme.colorScheme.primary,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open navigation menu',
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Semantics(
              button: true,
              label: 'lbl_juz_index'.tr,
              child: IconButton(
                icon: Icon(
                  Icons.view_module_rounded,
                  color: isDarkMode ? Colors.white : theme.colorScheme.primary,
                ),
                onPressed: () => _showJuzSelector(context),
                tooltip: 'lbl_juz_index'.tr,
              ),
            ),
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

                    if (RamadanTheme.isRamadan)
                      const SliverToBoxAdapter(child: RamadanCountdown()),

                    if (state is UpdateLastReadSurah && state.surah != null)
                      SliverToBoxAdapter(
                        child: _buildCardLastRead(state.surah, theme),
                      ),

                    SliverToBoxAdapter(
                      child: Semantics(
                        container: true,
                        label: 'lbl_surah_list'.tr,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final surah = QuranIndex.quranSurahs[index];
                        final isArabic =
                            Localizations.localeOf(context).languageCode ==
                            'ar';
                        final surahLabel = isArabic
                            ? surah.nameArabic
                            : surah.nameEnglish;

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
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Semantics(
                              button: true,
                              label:
                                  '$surahLabel, ${'lbl_surah'.tr} ${surah.id}',
                              child: InkWell(
                                onTap: () {
                                  PrefUtils().saveLastReadSurah(surah);
                                  homeBloc.add(HomeShowLastSurahEvent());
                                  _navigateToQuranView(surah: surah);
                                },
                                child: SurahListItem(
                                  surahId: surah.id,
                                  nameEnglish: surah.nameEnglish,
                                  nameArabic: surah.nameArabic,
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: QuranIndex.quranSurahs.length),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Navigate to Quran view based on user preference (Surah or Mushaf)
  void _navigateToQuranView({
    required Surah surah,
    int? verseIndex,
    double? offset,
    bool resume = false,
  }) {
    final defaultView = PrefUtils().getDefaultQuranView();

    if (defaultView == 'mushaf') {
      // Navigate to Mushaf view
      AppRoutes.goToMushaf(
        context,
        surah: surah.id,
        verse: verseIndex != null ? verseIndex + 1 : null,
      );
    } else {
      // Default: Navigate to Surah view
      NavigatorService.pushNamed(
        AppRoutes.surahPage,
        arguments: {
          'surah': surah,
          'verseIndex': verseIndex,
          'offset': offset,
          'resume': resume,
        },
      );
    }
  }

  /// Build navigation drawer with main navigation and extra options
  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return NavigationDrawer(
      selectedIndex: 0, // Home is selected
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            NavigatorService.pushNamed(AppRoutes.mushafScreen);
            break;
          case 2:
            NavigatorService.pushNamed(AppRoutes.searchPage);
            break;
          case 3:
            NavigatorService.pushNamed(AppRoutes.bookmarksPage);
            break;
          case 4:
            NavigatorService.pushNamed(AppRoutes.settingsScreen);
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
          icon: const Icon(Icons.home_rounded),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text('lbl_home'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book_rounded),
          label: Text('lbl_mushaf'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search_rounded),
          label: Text('lbl_search'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.bookmark_outline_rounded),
          selectedIcon: const Icon(Icons.bookmark_rounded),
          label: Text('lbl_bookmarks'.tr),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: Text('lbl_settings'.tr),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'lbl_more_options'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.bar_chart_rounded),
          title: Text('stats_title'.tr),
          onTap: () {
            Navigator.of(context).pop();
            NavigatorService.pushNamed(AppRoutes.statisticsScreen);
          },
        ),
        ListTile(
          leading: const Icon(Icons.playlist_add_check),
          title: Text('lbl_practice_list'.tr),
          onTap: () {
            Navigator.of(context).pop();
            NavigatorService.pushNamed(AppRoutes.recitationErrorsPage);
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text('about_title'.tr),
          onTap: () {
            Navigator.of(context).pop();
            NavigatorService.pushNamed(AppRoutes.aboutPage);
          },
        ),
        ListTile(
          leading: Icon(
            isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          ),
          title: Text('lbl_toggle_theme'.tr),
          onTap: () {
            Navigator.of(context).pop();
            themeBloc.add(ToggleThemeEvent());
            sl<AnalyticsService>().logThemeChange(!isDarkMode);
          },
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

                            _navigateToQuranView(
                              surah: lastReadSurah,
                              verseIndex: lastVerseIndex,
                              offset: offset,
                              resume: true,
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

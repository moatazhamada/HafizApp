import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/mushaf_screen/mushaf_screen.dart';
import '../presentation/search/search_screen.dart';
import '../presentation/bookmarks/bookmarks_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';

/// Adaptive navigation shell that switches between NavigationRail (tablet/desktop)
/// and NavigationDrawer (phone) based on screen width.
///
/// Provides Material 3 navigation pattern with 5 primary destinations:
/// Home, Mushaf, Search, Bookmarks, Settings
class AdaptiveNavigationShell extends StatefulWidget {
  const AdaptiveNavigationShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdaptiveNavigationShell> createState() =>
      _AdaptiveNavigationShellState();
}

class _AdaptiveNavigationShellState extends State<AdaptiveNavigationShell> {
  late int _selectedIndex;

  // Primary destination screens
  static const List<Widget> _destinations = [
    HomeScreen(),
    MushafScreen(),
    SearchScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Close drawer on mobile after selection
      if (MediaQuery.of(context).size.width <= 600) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Build drawer with extra options (Statistics, Practice List, About)
  Widget _buildDrawerWithExtras(ThemeData theme) {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      backgroundColor: theme.colorScheme.surface,
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
          icon: const Icon(Icons.home_outlined),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 600;

    if (isLargeScreen) {
      // Tablet/Desktop: NavigationRail layout
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.secondaryContainer,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        'app_name'.tr[0],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: Text('lbl_home'.tr),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book_rounded),
                  label: Text('lbl_mushaf'.tr),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search_rounded),
                  label: Text('lbl_search'.tr),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: Text('lbl_bookmarks'.tr),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: Text('lbl_settings'.tr),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _destinations,
              ),
            ),
          ],
        ),
      );
    } else {
      // Phone: NavigationDrawer layout - each screen handles its own AppBar
      return Scaffold(
        drawer: _buildDrawerWithExtras(theme),
        drawerEnableOpenDragGesture: true,
        // Removed appBar here to avoid duplicate with screen-specific app bars
        body: IndexedStack(index: _selectedIndex, children: _destinations),
      );
    }
  }
}

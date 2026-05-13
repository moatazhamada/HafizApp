import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../auth/bloc/qf_auth_bloc.dart';
import '../../../core/utils/rtl_utils.dart';

/// Navigation destination data shared between Drawer and Rail.
class _NavDestination {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavDestination({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

const List<_NavDestination> _destinations = [
  _NavDestination(
    labelKey: 'lbl_mushaf',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories_rounded,
    route: '/mushaf_screen',
  ),
  _NavDestination(
    labelKey: 'goals_title',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note_rounded,
    route: '/goals',
  ),
  _NavDestination(
    labelKey: 'lbl_bookmarks',
    icon: Icons.bookmark_outline_rounded,
    selectedIcon: Icons.bookmark_rounded,
    route: '/bookmarks',
  ),
  _NavDestination(
    labelKey: 'lbl_practice_list',
    icon: Icons.playlist_add_check_outlined,
    selectedIcon: Icons.playlist_add_check_rounded,
    route: '/recitation_errors',
  ),
  _NavDestination(
    labelKey: 'lbl_session_history',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history_rounded,
    route: '/recitation_sessions',
  ),
  _NavDestination(
    labelKey: 'lbl_memorization',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
    route: '/memorization',
  ),
  _NavDestination(
    labelKey: 'lbl_khatmah_tracker',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories_rounded,
    route: '/khatmah',
  ),
  _NavDestination(
    labelKey: 'stats_title',
    icon: Icons.trending_up_outlined,
    selectedIcon: Icons.trending_up_rounded,
    route: '/statistics',
  ),
];

const List<_NavDestination> _bottomDestinations = [
  _NavDestination(
    labelKey: 'lbl_settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: '/settings',
  ),
  _NavDestination(
    labelKey: 'about_title',
    icon: Icons.info_outline_rounded,
    selectedIcon: Icons.info_rounded,
    route: '/about_screen',
  ),
];

/// A widget that renders a [NavigationRail] for tablet layouts.
class AdaptiveNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: selectedIndex < _destinations.length ? selectedIndex : -1,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: colorScheme.surface,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.all(16),
        child: Icon(
          Icons.menu_book_rounded,
          color: colorScheme.primary,
          size: 28,
        ),
      ),
      destinations: [
        for (final dest in _destinations)
          NavigationRailDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: Text(dest.labelKey.tr),
          ),
        const NavigationRailDestination(
          icon: SizedBox.shrink(),
          label: SizedBox.shrink(),
        ),
        for (final dest in _bottomDestinations)
          NavigationRailDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: Text(dest.labelKey.tr),
          ),
      ],
    );
  }
}

/// A widget that renders a [NavigationDrawer] for phone layouts.
class AdaptiveNavigationDrawer extends StatelessWidget {
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavigationDrawer({
    super.key,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: null,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        onDestinationSelected(index);
      },
      children: [
        _buildDrawerAuthHeader(context),
        const Divider(height: 1),
        const SizedBox(height: 12),
        for (final dest in _destinations)
          NavigationDrawerDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: Text(dest.labelKey.tr),
          ),
        const Divider(height: 24),
        for (final dest in _bottomDestinations)
          NavigationDrawerDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: Text(dest.labelKey.tr),
          ),
      ],
    );
  }

  Widget _buildDrawerAuthHeader(BuildContext context) {
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, state) {
        final Widget avatar;
        final String title;
        final String subtitle;

        if (state is QfAuthAuthenticated) {
          final profile = state.profile;
          final initials = profile?.initials ??
              (state.userId?.isNotEmpty == true
                  ? state.userId![0].toUpperCase()
                  : '?');
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
          title = profile?.displayName ?? 'msg_qf_account'.tr;
          subtitle = profile?.email ?? 'msg_qf_logged_in'.tr;
        } else if (state is QfAuthLoading || state is QfAuthInitial) {
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        } else {
          avatar = CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  rtlChevron(context),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

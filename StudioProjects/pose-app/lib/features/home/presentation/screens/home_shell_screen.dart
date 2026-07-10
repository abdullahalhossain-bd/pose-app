import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Configuration for each bottom-nav destination.
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = <_NavDestination>[
  _NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  _NavDestination(
    icon: Icons.search,
    selectedIcon: Icons.search,
    label: 'Search',
  ),
  _NavDestination(
    icon: Icons.history,
    selectedIcon: Icons.history,
    label: 'History',
  ),
  _NavDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

/// Responsive home shell.
///
/// - Phone (`< 600dp` shortest side): Material 3 bottom [NavigationBar].
/// - Tablet / desktop (`>= 600dp`): Material 3 [NavigationRail] with the
///   FAB-style camera button docked at the bottom.
///
/// Both controls drive the same [StatefulNavigationShell], so tab
/// stacks are preserved regardless of form factor.
class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goTo(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isTablet) return _buildTablet(context);
    return _buildPhone(context);
  }

  Widget _buildPhone(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goTo,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _buildTablet(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goTo,
            extended: context.screenWidth >= 1024,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

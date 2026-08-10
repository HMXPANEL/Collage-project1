import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/eco_icons.dart';

/// Five-tab shell that keeps each branch alive via [StatefulNavigationShell].
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(EcoIcons.impact),
            selectedIcon: Icon(Icons.insights),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(EcoIcons.actions),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Actions',
          ),
          NavigationDestination(
            icon: Icon(EcoIcons.challenges),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          NavigationDestination(
            icon: Icon(EcoIcons.profile),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

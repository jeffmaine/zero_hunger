import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../claims/claims_screen.dart';
import '../home/map_screen.dart';
import '../home/nearby_feed_screen.dart';
import '../profile/profile_screen.dart';

class ReceiverShell extends StatefulWidget {
  const ReceiverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ReceiverShell> createState() => _ReceiverShellState();
}

class _ReceiverShellState extends State<ReceiverShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        backgroundColor: kSurface,
        indicatorColor: green100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Claims'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

List<Widget> receiverTabScreens() => const [
  NearbyFeedScreen(),
  MapScreen(),
  ClaimsScreen(),
  ProfileScreen(),
];

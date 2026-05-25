import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../donor/donor_home_screen.dart';
import '../donor/my_listings_screen.dart';
import '../profile/profile_screen.dart';

class DonorShell extends StatelessWidget {
  const DonorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      extendBody: false,
      body: navigationShell,
      floatingActionButton: SizedBox(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          onPressed: () => context.push('/donor/create'),
          backgroundColor: green500,
          elevation: 4,
          highlightElevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Material(
        elevation: 12,
        shadowColor: const Color(0x22000000),
        color: kSurface,
        child: SafeArea(
          top: false,
          child: BottomAppBar(
            height: 56,
            padding: EdgeInsets.zero,
            color: kSurface,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 7,
            surfaceTintColor: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: index == 0,
                    onTap: () => navigationShell.goBranch(0),
                  ),
                ),
                Expanded(
                  child: _ListingsUnderFab(
                    selected: index == 1,
                    onTap: () => navigationShell.goBranch(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: index == 2,
                    onTap: () => navigationShell.goBranch(2, initialLocation: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Listings" label centered in the notch, directly under the + FAB.
class _ListingsUnderFab extends StatelessWidget {
  const _ListingsUnderFab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? green500 : kTextDisabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 26),
              Text(
                'Listings',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? green500 : kTextDisabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> donorTabScreens() => const [
  DonorHomeScreen(),
  MyListingsScreen(),
  ProfileScreen(),
];

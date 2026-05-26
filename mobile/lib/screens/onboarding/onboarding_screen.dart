import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../services/token_storage.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  UserRole? _selectedRole;

  final _pages = const [
    _Slide(
      icon: Icons.restaurant,
      title: 'Share food, reduce waste',
      body: 'Post your leftover food in under 60 seconds.',
    ),
    _Slide(
      icon: Icons.place,
      title: 'Find food near you',
      body: 'See available food nearby and claim it instantly.',
    ),
  ];

  Future<void> _finish() async {
    if (_selectedRole == null) return;
    if (_selectedRole == UserRole.volunteer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(kVolunteerPhase2Message)),
      );
      return;
    }
    await ref.read(tokenStorageProvider).setPendingRole(_selectedRole!.apiValue);
    await ref.read(tokenStorageProvider).setOnboarded(true);
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final isRolePage = _page == 2;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        actions: [
          if (_page < 2)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                ..._pages.map((s) => _SlideView(slide: s)),
                _RoleSelectPage(
                  selected: _selectedRole,
                  onSelect: (r) => setState(() => _selectedRole = r),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _page == i ? green500 : gray300,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              label: isRolePage ? 'Continue' : 'Next',
              enabled: !isRolePage || _selectedRole != null,
              onPressed: () {
                if (isRolePage) {
                  _finish();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: green100, shape: BoxShape.circle),
            child: Icon(slide.icon, size: 56, color: green500),
          ),
          const Spacer(),
          Text(slide.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _RoleSelectPage extends StatelessWidget {
  const _RoleSelectPage({required this.selected, required this.onSelect});

  final UserRole? selected;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text('How will you use Zero Hunger?', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _RoleCard(
            icon: Icons.storefront_outlined,
            title: 'I have food to share',
            role: UserRole.donor,
            selected: selected == UserRole.donor,
            onTap: () => onSelect(UserRole.donor),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.back_hand_outlined,
            title: "I'm looking for food",
            role: UserRole.receiver,
            selected: selected == UserRole.receiver,
            onTap: () => onSelect(UserRole.receiver),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.pedal_bike_outlined,
            title: 'I want to help deliver',
            role: UserRole.volunteer,
            selected: selected == UserRole.volunteer,
            onTap: () => onSelect(UserRole.volunteer),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? green100 : kSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? green500 : kBorder, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? green500 : kTextSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ),
    );
  }
}

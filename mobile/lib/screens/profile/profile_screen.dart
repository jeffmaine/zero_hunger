import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_providers.dart';
import '../../providers/geo_provider.dart';
import '../../providers/listings_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/format.dart';
import '../../utils/pickup_area_copy.dart';
import '../../widgets/location_picker_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final profileAsync = ref.watch(profileProvider);
    final user = profileAsync.valueOrNull ?? auth.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: green500)),
      );
    }

    final geo = ref.watch(geoProvider);
    final isDonor = user.role == UserRole.donor;
    final displayName = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .map(formatFirstName)
        .join(' ');

    if (profileAsync.hasError && profileAsync.valueOrNull == null && auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${profileAsync.error}', textAlign: TextAlign.center, style: const TextStyle(color: kErrorText)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: green100,
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: green500, fontWeight: FontWeight.w700, fontSize: 24),
                              )
                            : null,
                      ),
                      if (user.isVerified)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.verified, color: green500, size: 22),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: green100, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      roleLabels[user.role.apiValue] ?? user.role.name,
                      style: const TextStyle(fontSize: 11, color: green500),
                    ),
                  ),
                  if (isDonor && user.organizationName != null && user.organizationName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(user.organizationName!, style: const TextStyle(fontSize: 14, color: kTextSecondary)),
                  ],
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(user.bio!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                  ],
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(user.phone, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                  ],
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.email, style: const TextStyle(fontSize: 12, color: kTextDisabled)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDonor) ...[
                        _StatChip(label: 'Meals shared', value: '${user.mealsShared}'),
                        const SizedBox(width: 12),
                      ] else ...[
                        _StatChip(label: 'Pickups', value: '${user.successfulPickups}'),
                        const SizedBox(width: 12),
                      ],
                      _StatChip(
                        label: 'Member since',
                        value: DateFormat('MMM yyyy').format(user.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              children: [
                _SettingsTile(
                  icon: Icons.place_outlined,
                  title: isDonor ? 'Pickup area' : 'Preferred area',
                  subtitle: geo.hasCoords
                      ? '${geo.displayTitle} · ${geo.sourceBadge}'
                      : 'Where you pick up food — tap to set',
                  onTap: () => showLocationPickerSheet(context, ref),
                ),
                if (user.role == UserRole.receiver)
                  _SettingsTile(
                    icon: Icons.radar,
                    title: 'Search radius',
                    subtitle: '${geo.radiusKm.toStringAsFixed(0)} km',
                    onTap: () => _showRadiusSheet(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About Zero Hunger',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Zero Hunger',
                    applicationVersion: 'MVP',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: kBorder),
              ),
              tileColor: kSurface,
              title: const Text('Log out', style: TextStyle(color: kErrorText)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                invalidateSessionProviders(ref);
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showRadiusSheet(BuildContext context, WidgetRef ref) {
    final geo = ref.read(geoProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search radius', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...radiusOptionsKm.map((km) {
              final selected = geo.radiusKm == km;
              return ListTile(
                title: Text('${km.toStringAsFixed(0)} km'),
                trailing: selected ? const Icon(Icons.check, color: green500) : null,
                onTap: () {
                  ref.read(geoProvider.notifier).setRadius(km);
                  ref.invalidate(nearbyListingsProvider);
                  ref.invalidate(mapPinsProvider);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: green50, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: green500)),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kTextSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: kTextDisabled),
      onTap: onTap,
    );
  }
}

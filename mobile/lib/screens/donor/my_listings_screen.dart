import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/donor_impact_banner.dart';
import '../../widgets/donor_listing_tile.dart';
import '../../widgets/listings_food_illustration.dart';
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _ListingStats {
  const _ListingStats({required this.active, required this.completed, required this.expired});

  final int active;
  final int completed;
  final int expired;
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  _ListingStats _stats(List<ListingModel> all) {
    final active = all
        .where((l) => l.status == ListingStatus.available || l.status == ListingStatus.claimed)
        .length;
    final completed = all.where((l) => l.status == ListingStatus.completed).length;
    final expired = all.where((l) => l.status == ListingStatus.expired).length;
    return _ListingStats(active: active, completed: completed, expired: expired);
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: listingsAsync.when(
          loading: () => const Column(
            children: [
              _ListingsPageHeader(),
              SizedBox(height: 12),
              Expanded(child: Center(child: CircularProgressIndicator(color: green500))),
            ],
          ),
          error: (e, _) => Column(
            children: [
              const _ListingsPageHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('$e', style: TextStyle(color: kErrorText)),
                  ),
                ),
              ),
            ],
          ),
          data: (listings) {
            final stats = _stats(listings);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ListingsPageHeader(),
                _ListingsTabBar(controller: _tabs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ListingsStatsCard(stats: stats),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _ListTab(
                        listings: listings
                            .where((l) =>
                                l.status == ListingStatus.available ||
                                l.status == ListingStatus.claimed)
                            .toList(),
                        tab: _ListingsTabKind.active,
                      ),
                      _ListTab(
                        listings:
                            listings.where((l) => l.status == ListingStatus.completed).toList(),
                        tab: _ListingsTabKind.completed,
                      ),
                      _ListTab(
                        listings:
                            listings.where((l) => l.status == ListingStatus.expired).toList(),
                        tab: _ListingsTabKind.expired,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListingsPageHeader extends StatelessWidget {
  const _ListingsPageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My listings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: kTextPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track your surplus food and make an impact. 🌱',
                  style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          Material(
            color: green100,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => DonorImpactBanner.showHowItWorks(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline_rounded, size: 16, color: green500.withValues(alpha: 0.9)),
                    const SizedBox(width: 4),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: green500.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsTabBar extends StatelessWidget {
  const _ListingsTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: green500,
      unselectedLabelColor: kTextDisabled,
      indicatorColor: green500,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Active'),
        Tab(text: 'Completed'),
        Tab(text: 'Expired'),
      ],
    );
  }
}

class _ListingsStatsCard extends StatelessWidget {
  const _ListingsStatsCard({required this.stats});

  final _ListingStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.work_outline_rounded,
              iconColor: green500,
              iconBg: green100,
              value: '${stats.active}',
              label: 'Active listings',
            ),
          ),
          _divider(),
          Expanded(
            child: _StatCell(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFFC9A227),
              iconBg: const Color(0xFFFFF8E1),
              value: '${stats.completed}',
              label: 'Completed donations',
            ),
          ),
          _divider(),
          Expanded(
            child: _StatCell(
              icon: Icons.hourglass_empty_rounded,
              iconColor: kErrorText,
              iconBg: kErrorBg,
              value: '${stats.expired}',
              label: 'Expired listings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 48, color: kBorder.withValues(alpha: 0.8));
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: kTextSecondary, height: 1.2),
        ),
      ],
    );
  }
}

enum _ListingsTabKind { active, completed, expired }

class _ListTab extends ConsumerWidget {
  const _ListTab({required this.listings, required this.tab});

  final List<ListingModel> listings;
  final _ListingsTabKind tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listings.isEmpty) {
      return _ListingsEmptyState(tab: tab);
    }
    return RefreshIndicator(
      color: green500,
      onRefresh: () async => ref.invalidate(myListingsProvider),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 14, 16, donorScrollBottomInset(context)),
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final l = listings[i];
          return DonorListingTile(
            listing: l,
            onTap: () => context.push('/donor/listing/${l.id}'),
          );
        },
      ),
    );
  }
}

class _ListingsEmptyState extends StatelessWidget {
  const _ListingsEmptyState({required this.tab});

  final _ListingsTabKind tab;

  void _showTips(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: gray300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tips for great listings', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _TipRow(text: 'Use a clear title — e.g. “Jollof rice”, not “food”.'),
            const _TipRow(text: 'Set a realistic pickup window (a few hours works best).'),
            const _TipRow(text: 'Say how many portions — “Feeds 3–4 people”.'),
            const _TipRow(text: 'Add a photo when you can — listings get claimed faster.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(backgroundColor: green500),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, body, showPost) = switch (tab) {
      _ListingsTabKind.active => (
          "You don't have any active listings",
          'Share your surplus food with someone in need and help reduce food waste.',
          true,
        ),
      _ListingsTabKind.completed => (
          'No completed listings yet',
          'When pickups are done, completed listings will appear here.',
          false,
        ),
      _ListingsTabKind.expired => (
          'No expired listings',
          'Listings past their pickup window show up here.',
          false,
        ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 8, 20, donorScrollBottomInset(context)),
      children: [
        const SizedBox(height: 12),
        const Center(child: ListingsFoodIllustration(size: 130)),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4),
        ),
        if (showPost) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/donor/create'),
            style: FilledButton.styleFrom(
              backgroundColor: green500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text('Post surplus food', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showTips(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: green500,
              side: const BorderSide(color: green500),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            label: const Text('Tips for great listings', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: green500),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.35))),
        ],
      ),
    );
  }
}

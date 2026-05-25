import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/donor_dashboard.dart';
import '../../providers/donor_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geo_provider.dart';
import '../../providers/listings_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../utils/format.dart';
import '../../utils/greeting.dart';
import '../../widgets/donor_home_listing_card.dart';
import '../../widgets/donor_impact_banner.dart';
import '../../widgets/donor_post_cta.dart';
import '../../widgets/donor_stat_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/skeleton_card.dart';
import '../../core/layout.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    await ref.read(geoProvider.notifier).ensureLocation();
    if (mounted) {
      ref.invalidate(donorDashboardProvider);
      ref.invalidate(unreadNotificationsProvider);
    }
  }

  Future<void> _refresh() async {
    await ref.read(geoProvider.notifier).ensureLocation();
    ref.invalidate(donorDashboardProvider);
    ref.invalidate(myListingsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(donorDashboardProvider);

    ref.listen(geoProvider, (prev, next) {
      if (prev?.latitude != next.latitude || prev?.longitude != next.longitude) {
        ref.invalidate(donorDashboardProvider);
      }
    });

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: green500,
          onRefresh: _refresh,
          child: dashboardAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, donorScrollBottomInset(context)),
            children: const [
              _HeaderSkeleton(),
              SizedBox(height: 16),
              Row(children: [Expanded(child: SkeletonCard()), SizedBox(width: 12), Expanded(child: SkeletonCard())]),
              SizedBox(height: 14),
              SkeletonCard(),
              SizedBox(height: 20),
              SkeletonCard(),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('$e', style: const TextStyle(color: kErrorText)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            ],
          ),
          data: (dashboard) => _DashboardBody(dashboard: dashboard, onRefresh: _refresh),
        ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.dashboard, required this.onRefresh});

  final DonorDashboardModel dashboard;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = dashboard.stats;
    final recent = dashboard.recentListings;
    final activity = dashboard.nearbyActivity;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
            child: _HomeHeader(
              unreadCount: stats.unreadNotifications,
              onProfile: () {
                final shell = StatefulNavigationShell.maybeOf(context);
                if (shell != null) {
                  shell.goBranch(2, initialLocation: true);
                } else {
                  context.go('/donor/profile');
                }
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              children: [
                DonorStatCard(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: green500,
                  iconBg: green100,
                  count: stats.activeListings,
                  title: stats.activeListings == 1 ? 'Active Listing' : 'Active Listings',
                  subtitle: 'Currently available',
                ),
                const SizedBox(width: 12),
                DonorStatCard(
                  icon: Icons.assignment_outlined,
                  iconColor: kAccent,
                  iconBg: const Color(0xFFFFF3E0),
                  count: stats.totalPosted,
                  title: stats.totalPosted == 1 ? 'Total Posted' : 'Total Posted',
                  subtitle: 'All time',
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: DonorPostCta(onTap: () => context.push('/donor/create')),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent listings',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextPrimary),
                ),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/donor/listings'),
                    style: TextButton.styleFrom(
                      foregroundColor: green500,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
        if (recent.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EmptyState(
                title: 'No listings yet',
                body: 'Post your first surplus food — someone nearby may claim it today.',
                icon: Icons.restaurant_menu_rounded,
                actionLabel: 'Post food now',
                onAction: () => context.push('/donor/create'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final listing = recent[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DonorHomeListingCard(
                      listing: listing,
                      onTap: () => context.push('/donor/listing/${listing.id}'),
                      onMenu: (action) {
                        if (action == 'view') {
                          context.push('/donor/listing/${listing.id}');
                        } else {
                          context.go('/donor/listings');
                        }
                      },
                    ),
                  );
                },
                childCount: recent.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: DonorImpactBanner(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Text(
              'Nearby activity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                    fontSize: 17,
                  ),
            ),
          ),
        ),
        if (activity.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                ref.watch(geoProvider).hasCoords
                    ? 'No other posts nearby yet. Check back soon.'
                    : 'Enable location to see food posted near you.',
                style: const TextStyle(fontSize: 13, color: kTextSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = activity[i];
                  return _NearbyActivityTile(
                    item: item,
                    onTap: () => context.push('/donor/listing/${item.listingId}'),
                  );
                },
                childCount: activity.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: donorScrollBottomInset(context))),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.unreadCount, required this.onProfile});

  final int unreadCount;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final firstName = formatFirstName(user?.name);
    final initials = user?.name != null && user!.name.trim().isNotEmpty
        ? user.name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase()
        : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${timeOfDayGreeting()},',
                style: const TextStyle(fontSize: 15, color: kTextSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                '$firstName 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Together we can end food waste',
                style: TextStyle(fontSize: 13, color: kTextSecondary),
              ),
            ],
          ),
        ),
        NotificationBellButton(badgeCount: unreadCount),
        GestureDetector(
          onTap: onProfile,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: green200, width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: green100,
              child: Text(
                initials,
                style: const TextStyle(color: green500, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 120, height: 14, color: gray100),
        const SizedBox(height: 8),
        Container(width: 180, height: 28, color: gray100),
      ],
    );
  }
}

class _NearbyActivityTile extends StatelessWidget {
  const _NearbyActivityTile({required this.item, this.onTap});

  final NearbyActivityModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final donor = formatFirstName(item.donorName, fallback: item.donorName);
    final title = formatListingTitle(item.listingTitle);
    final meta = item.distanceKm != null
        ? '${formatRelativeTimeAgo(item.createdAt)} · ${formatDistanceKm(item.distanceKm)} away'
        : formatRelativeTimeAgo(item.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
            SizedBox(
              width: 44,
              height: 28,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: green100,
                      child: Text(
                        donor.isNotEmpty ? donor[0] : '?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: green500),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: gray100,
                      child: Icon(Icons.person, size: 14, color: kTextDisabled.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: kTextPrimary),
                      children: [
                        TextSpan(text: donor, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const TextSpan(text: ' posted '),
                        TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                ],
              ),
            ),
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: green100, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.restaurant, size: 22, color: green500),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geo_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/listings_provider.dart';
import '../../utils/claim_ui.dart';
import '../../utils/greeting.dart';
import '../../utils/pickup_area_copy.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/food_card.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/skeleton_card.dart';

class NearbyFeedScreen extends ConsumerStatefulWidget {
  const NearbyFeedScreen({super.key});

  @override
  ConsumerState<NearbyFeedScreen> createState() => _NearbyFeedScreenState();
}

class _NearbyFeedScreenState extends ConsumerState<NearbyFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(geoProvider.notifier).ensureLocation();
      if (mounted) ref.invalidate(nearbyListingsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final geo = ref.watch(geoProvider);
    final category = ref.watch(selectedCategoryProvider);
    final listingsAsync = ref.watch(nearbyListingsProvider);
    final count = listingsAsync.valueOrNull?.length;

    ref.listen(geoProvider, (_, __) {
      ref.invalidate(nearbyListingsProvider);
    });

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
        color: green500,
        onRefresh: () async {
          await ref.read(geoProvider.notifier).ensureLocation();
          ref.invalidate(nearbyListingsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [green500, Color(0xFF1B4332)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A2D6A4F),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greetingWithName(user?.name),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${count ?? '…'} listings near your pickup area',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          child: const NotificationBellButton(iconSize: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => showLocationPickerSheet(context, ref),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.place_outlined, size: 22, color: Colors.white.withValues(alpha: 0.95)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pickup area · ${geo.displayTitle}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      geo.source == LocationSource.gps
                                          ? 'Using live GPS — tap to pick a junction or place you’ll be at'
                                          : 'Showing food near this spot — tap to change',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                        color: Colors.white.withValues(alpha: 0.82),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.9)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RadiusChipRow(
                  selectedKm: geo.radiusKm,
                  onSelected: (km) {
                    ref.read(geoProvider.notifier).setRadius(km);
                    ref.invalidate(nearbyListingsProvider);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: CategoryChipRow(
                  selected: category,
                  onSelected: (c) {
                    ref.read(selectedCategoryProvider.notifier).state = c;
                    ref.invalidate(nearbyListingsProvider);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('NEARBY NOW', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
            listingsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SkeletonCard(),
                  ),
                  childCount: 5,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(nearbyListingsProvider),
                ),
              ),
              data: (listings) {
                final myClaims = ref.watch(myClaimsProvider).valueOrNull ?? [];
                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: 'No food near this pickup area',
                      body: 'Try a larger radius, search another junction or area, '
                          'or use current location if you moved.',
                      actionLabel: 'Change pickup area',
                      onAction: () => showLocationPickerSheet(context, ref),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final listing = listings[i];
                        final myClaim = findMyClaimForListing(myClaims, listing.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FoodCard(
                            listing: listing,
                            claimButtonLabel: foodCardClaimLabel(
                              listing: listing,
                              myClaim: myClaim,
                            ),
                            onTap: () => context.push('/receiver/food/${listing.id}'),
                            onClaim: () => context.push('/receiver/food/${listing.id}'),
                          ),
                        );
                      },
                      childCount: listings.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        ),
      ),
    );
  }
}

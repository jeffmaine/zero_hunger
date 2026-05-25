import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/claims_provider.dart';
import '../../providers/listings_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/claim_service.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/claim_limits_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  bool _claiming = false;

  Future<void> _claim() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Claim this food?', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'The donor reviews your request — not fastest-finger wins. '
              'You can have up to 2 active claims at a time.',
              style: TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Yes, claim',
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _claiming = true);
    try {
      await ref.read(claimServiceProvider).createClaim(widget.listingId);
      ref.invalidate(myClaimsProvider);
      ref.invalidate(unreadNotificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted — pending approval')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final limitsAsync = ref.watch(claimLimitsProvider);

    return listingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: green500))),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(listingDetailProvider(widget.listingId))),
      ),
      data: (listing) => Scaffold(
        backgroundColor: kBackground,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: green500,
                  flexibleSpace: FlexibleSpaceBar(
                    background: listing.imageUrl != null
                        ? CachedNetworkImage(imageUrl: listing.imageUrl!, fit: BoxFit.cover)
                        : Container(color: green200, child: const Icon(Icons.restaurant, size: 64, color: green500)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatListingTitle(listing.title),
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                              StatusBadge.listing(listing.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: kTextSecondary),
                              Text(' ${formatDistanceKm(listing.distanceKm)} · ', style: Theme.of(context).textTheme.bodySmall),
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: listingDeadlineColor(
                                  status: listing.status,
                                  deadline: listing.pickupDeadline,
                                ),
                              ),
                              Text(
                                ' ${formatListingDeadline(status: listing.status, deadline: listing.pickupDeadline)}',
                                style: TextStyle(
                                  color: listingDeadlineColor(
                                    status: listing.status,
                                    deadline: listing.pickupDeadline,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('ABOUT THIS FOOD', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 8),
                          Text(listing.description ?? 'No additional details.', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          Text('${listing.quantity} available', style: Theme.of(context).textTheme.bodySmall),
                          const Divider(height: 24),
                          Text('PICKUP LOCATION', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 8),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: gray100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: const Center(child: Icon(Icons.map_outlined, color: kTextDisabled, size: 40)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${listing.latitude.toStringAsFixed(4)}, ${listing.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: green100,
                                child: Text(
                                  (listing.donorName ?? 'D').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: green500, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Posted by ${listing.donorName ?? 'Donor'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const Text('Donor', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: kSurface,
                  border: Border(top: BorderSide(color: kBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    limitsAsync.when(
                      data: (limits) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClaimLimitsBanner(limits: limits),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    PrimaryButton(
                      label: 'Request claim',
                      isLoading: _claiming,
                      onPressed: listing.status.name == 'available' ? _claim : null,
                      enabled: listing.status.name == 'available' &&
                          (limitsAsync.valueOrNull?.canClaim ?? true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

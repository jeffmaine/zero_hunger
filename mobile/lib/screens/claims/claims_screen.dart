import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/claim.dart';
import '../../models/enums.dart';
import '../../providers/claims_provider.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pickup_code_chip.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/status_badge.dart';

class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key, this.isDonorView = false});

  final bool isDonorView;

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.statuses,
    required this.emptyTitle,
    required this.emptyBody,
    this.emptyAction,
  });

  final String label;
  final List<ClaimStatus> statuses;
  final String emptyTitle;
  final String emptyBody;
  final String? emptyAction;
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late List<_TabSpec> _tabSpecs;

  @override
  void initState() {
    super.initState();
    _tabSpecs = _buildTabSpecs();
    _tabs = TabController(length: _tabSpecs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_TabSpec> _buildTabSpecs() {
    if (widget.isDonorView) {
      return const [
        _TabSpec(
          label: 'Pending',
          statuses: [ClaimStatus.pending],
          emptyTitle: 'No pending claims',
          emptyBody: 'When someone requests your food, they appear here for you to review.',
        ),
        _TabSpec(
          label: 'Approved',
          statuses: [ClaimStatus.approved, ClaimStatus.collected],
          emptyTitle: 'No approved claims',
          emptyBody: 'Approved and collected claims on your listings show here.',
        ),
        _TabSpec(
          label: 'Rejected',
          statuses: [ClaimStatus.rejected],
          emptyTitle: 'No rejected claims',
          emptyBody: 'Claims you decline are kept here for reference.',
        ),
      ];
    }
    return const [
      _TabSpec(
        label: 'Pending',
        statuses: [ClaimStatus.pending],
        emptyTitle: 'Nothing waiting',
        emptyBody: 'Claims awaiting donor approval will show up here.',
        emptyAction: 'Browse food',
      ),
      _TabSpec(
        label: 'Approved',
        statuses: [ClaimStatus.approved],
        emptyTitle: 'No approved pickups',
        emptyBody: 'When a donor approves your claim, your pickup code appears here.',
      ),
      _TabSpec(
        label: 'Collected',
        statuses: [ClaimStatus.collected],
        emptyTitle: 'No pickups yet',
        emptyBody: 'Food you have successfully collected will be listed here.',
      ),
      _TabSpec(
        label: 'Rejected',
        statuses: [ClaimStatus.rejected],
        emptyTitle: 'No declined claims',
        emptyBody: 'If a donor declines a request, you will see it here.',
        emptyAction: 'Browse food',
      ),
    ];
  }

  List<ClaimModel> _filter(List<ClaimModel> claims, _TabSpec spec) {
    final list = claims.where((c) => spec.statuses.contains(c.status)).toList();
    list.sort((a, b) {
      final aTime = a.collectedAt ?? a.createdAt;
      final bTime = b.collectedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  int _count(List<ClaimModel> claims, _TabSpec spec) {
    return claims.where((c) => spec.statuses.contains(c.status)).length;
  }

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(myClaimsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(widget.isDonorView ? 'Claims on listings' : 'My claims'),
        bottom: claimsAsync.maybeWhen(
          data: (claims) => _ClaimsTabBar(
            controller: _tabs,
            specs: _tabSpecs,
            counts: _tabSpecs.map((s) => _count(claims, s)).toList(),
          ),
          orElse: () => TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: green500,
            unselectedLabelColor: kTextDisabled,
            indicatorColor: green500,
            tabs: _tabSpecs.map((s) => Tab(text: s.label)).toList(),
          ),
        ),
      ),
      body: claimsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const SkeletonCard(),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myClaimsProvider),
        ),
        data: (claims) => TabBarView(
          controller: _tabs,
          children: _tabSpecs.map((spec) {
            final filtered = _filter(claims, spec);
            if (filtered.isEmpty) {
              return EmptyState(
                title: spec.emptyTitle,
                body: spec.emptyBody,
                actionLabel: spec.emptyAction,
                onAction: spec.emptyAction != null ? () => context.go('/receiver') : null,
              );
            }
            return RefreshIndicator(
              color: green500,
              onRefresh: () async => ref.invalidate(myClaimsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final claim = filtered[i];
                  return widget.isDonorView
                      ? _DonorClaimCard(claim: claim)
                      : _ReceiverClaimCard(
                          claim: claim,
                          onTap: () {
                            final id = claim.listingId;
                            if (id.isNotEmpty) context.push('/receiver/food/$id');
                          },
                        );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ClaimsTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _ClaimsTabBar({
    required this.controller,
    required this.specs,
    required this.counts,
  });

  final TabController controller;
  final List<_TabSpec> specs;
  final List<int> counts;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: specs.length > 3,
      tabAlignment: specs.length > 3 ? TabAlignment.start : TabAlignment.fill,
      labelColor: green500,
      unselectedLabelColor: kTextDisabled,
      indicatorColor: green500,
      indicatorWeight: 2.5,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      tabs: List.generate(specs.length, (i) {
        final count = counts[i];
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(specs[i].label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: controller.index == i ? green100 : gray100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: controller.index == i ? green500 : kTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ReceiverClaimCard extends StatelessWidget {
  const _ReceiverClaimCard({required this.claim, this.onTap});

  final ClaimModel claim;
  final VoidCallback? onTap;

  String get _statusHint {
    return switch (claim.status) {
      ClaimStatus.pending => 'Waiting for donor to review your request',
      ClaimStatus.approved => 'Go pickup — show the code below to the donor',
      ClaimStatus.collected => 'Pickup completed · thanks for reducing waste',
      ClaimStatus.rejected => 'This request was not approved',
    };
  }

  @override
  Widget build(BuildContext context) {
    final listing = claim.listing;
    final title = formatListingTitle(listing?.title ?? 'Food listing');

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (listing?.imageUrl != null && listing!.imageUrl!.isNotEmpty)
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CachedNetworkImage(imageUrl: listing.imageUrl!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.claim(claim.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusHint,
                    style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
                  ),
                  if (listing != null &&
                      (claim.status == ClaimStatus.pending || claim.status == ClaimStatus.approved)) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: kTextDisabled),
                        const SizedBox(width: 4),
                        Text(
                          'Pickup by ${formatListingDeadline(status: listing.status, deadline: listing.pickupDeadline)}',
                          style: const TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ],
                  if (claim.status == ClaimStatus.collected) ...[
                    const SizedBox(height: 6),
                    Text(
                      claim.collectedAt != null
                          ? 'Collected ${formatRelativeTimeAgo(claim.collectedAt!)}'
                          : 'Collected ${formatRelativeTimeAgo(claim.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                  if (claim.status == ClaimStatus.rejected) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Requested ${formatRelativeTimeAgo(claim.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: kTextDisabled),
                    ),
                  ],
                  if (claim.pickupCode != null && claim.status == ClaimStatus.approved) ...[
                    const SizedBox(height: 12),
                    PickupCodeChip(code: claim.pickupCode!, label: 'Your pickup code'),
                  ],
                  if (claim.status != ClaimStatus.rejected) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'View listing',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: green500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorClaimCard extends StatelessWidget {
  const _DonorClaimCard({required this.claim});

  final ClaimModel claim;

  @override
  Widget build(BuildContext context) {
    final listing = claim.listing;
    final title = formatListingTitle(listing?.title ?? 'Food listing');
    final receiver = claim.receiverName ?? 'Receiver';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: green100,
                child: Text(
                  receiver.isNotEmpty ? receiver[0].toUpperCase() : '?',
                  style: const TextStyle(color: green500, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(receiver, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                  ],
                ),
              ),
              StatusBadge.claim(claim.status),
            ],
          ),
          if (claim.pickupCode != null &&
              (claim.status == ClaimStatus.approved || claim.status == ClaimStatus.collected)) ...[
            const SizedBox(height: 10),
            PickupCodeChip(
              code: claim.pickupCode!,
              label: claim.status == ClaimStatus.approved ? 'Receiver pickup code' : 'Code used at pickup',
            ),
          ],
        ],
      ),
    );
  }
}

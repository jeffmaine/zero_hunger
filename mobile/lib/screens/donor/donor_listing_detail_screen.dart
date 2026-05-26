import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/claim.dart';
import '../../models/enums.dart';
import '../../providers/claims_provider.dart';
import '../../providers/listings_provider.dart';
import '../../providers/donor_dashboard_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/claim_service.dart';
import '../../services/listing_service.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/pickup_code_chip.dart';
import '../../widgets/status_badge.dart';
import 'edit_listing_screen.dart';

class DonorListingDetailScreen extends ConsumerStatefulWidget {
  const DonorListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<DonorListingDetailScreen> createState() => _DonorListingDetailScreenState();
}

class _DonorListingDetailScreenState extends ConsumerState<DonorListingDetailScreen> {
  String? _actionClaimId;

  void _refresh() {
    ref.invalidate(listingDetailProvider(widget.listingId));
    ref.invalidate(listingClaimsProvider(widget.listingId));
    ref.invalidate(myListingsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(donorDashboardProvider);
  }

  Future<void> _approve(String claimId) async {
    setState(() => _actionClaimId = claimId);
    try {
      await ref.read(claimServiceProvider).approveClaim(claimId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  Future<void> _reject(String claimId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject claim?'),
        content: const Text('The receiver will be notified this claim was declined.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: kErrorText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionClaimId = claimId);
    try {
      await ref.read(claimServiceProvider).rejectClaim(claimId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  Future<void> _setStatus(ListingStatus status) async {
    setState(() => _actionClaimId = '_status');
    try {
      await ref.read(listingServiceProvider).patchStatus(widget.listingId, status);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: ${status.name}')));
        if (status == ListingStatus.cancelled) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  Future<void> _extendDeadline() async {
    final listing = ref.read(listingDetailProvider(widget.listingId)).valueOrNull;
    if (listing == null) return;
    final newDeadline = listing.pickupDeadline.add(const Duration(hours: 2));
    setState(() => _actionClaimId = '_extend');
    try {
      await ref.read(listingServiceProvider).update(widget.listingId, {
        'pickup_deadline': newDeadline.toUtc().toIso8601String(),
      });
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deadline extended by 2 hours')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  Future<void> _deleteListing() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: kErrorText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(listingServiceProvider).deleteListing(widget.listingId);
      ref.invalidate(myListingsProvider);
      ref.invalidate(donorDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _markNoShow(ClaimModel claim) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as no-show?'),
        content: const Text(
          'The receiver did not pick up. This counts against their account and re-opens the listing for others.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('No-show', style: TextStyle(color: kErrorText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionClaimId = claim.id);
    try {
      await ref.read(claimServiceProvider).markNoShow(claim.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked no-show — listing available again')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  Future<void> _confirmPickup(ClaimModel approved) async {
    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm pickup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask the receiver for their 4-digit pickup code, then enter it here.',
              style: TextStyle(fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Pickup code',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final entered = codeController.text.trim();
              if (entered.length == 4) Navigator.pop(ctx, entered);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    codeController.dispose();
    if (code == null || code.length != 4 || !mounted) return;

    setState(() => _actionClaimId = approved.id);
    try {
      await ref.read(claimServiceProvider).collectClaim(approved.id, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup confirmed — listing completed')),
        );
        Navigator.pop(context);
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _actionClaimId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final claimsAsync = ref.watch(listingClaimsProvider(widget.listingId));

    return listingAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green500)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: '$e', onRetry: _refresh),
      ),
      data: (listing) {
        final claims = claimsAsync.valueOrNull ?? [];
        final claimsLoading = claimsAsync.isLoading && !claimsAsync.hasValue;
        final pending = claims.where((c) => c.status == ClaimStatus.pending).toList();
        final approved = claims.where((c) => c.status == ClaimStatus.approved).toList();
        final approvedClaim = approved.isNotEmpty ? approved.first : null;
        final canConfirmPickup = approvedClaim != null;

        return Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            title: const Text('Listing'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) => EditListingScreen(listing: listing)),
                      );
                      _refresh();
                    case 'extend':
                      _extendDeadline();
                    case 'pause':
                      _setStatus(ListingStatus.paused);
                    case 'resume':
                      _setStatus(ListingStatus.available);
                    case 'cancel':
                      _setStatus(ListingStatus.cancelled);
                    case 'delete':
                      _deleteListing();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit listing')),
                  const PopupMenuItem(value: 'extend', child: Text('Extend deadline (+2h)')),
                  if (listing.status == ListingStatus.available)
                    const PopupMenuItem(value: 'pause', child: Text('Pause listing')),
                  if (listing.status == ListingStatus.paused)
                    const PopupMenuItem(value: 'resume', child: Text('Resume listing')),
                  if (listing.status != ListingStatus.cancelled && listing.status != ListingStatus.completed)
                    const PopupMenuItem(value: 'cancel', child: Text('Cancel listing')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete listing')),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            ],
          ),
          body: RefreshIndicator(
            color: green500,
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: listing.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: green100,
                            child: const Icon(Icons.restaurant_rounded, size: 48, color: green500),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatListingTitle(listing.title),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge.listing(listing.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(listing.quantity, style: Theme.of(context).textTheme.bodySmall),
                    const Text(' · ', style: TextStyle(color: kTextDisabled)),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: listingDeadlineColor(
                        status: listing.status,
                        deadline: listing.pickupDeadline,
                      ),
                    ),
                    Text(
                      ' ${formatListingDeadline(status: listing.status, deadline: listing.pickupDeadline)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: listingDeadlineColor(
                          status: listing.status,
                          deadline: listing.pickupDeadline,
                        ),
                      ),
                    ),
                  ],
                ),
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(listing.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                Text('CLAIMS', style: Theme.of(context).textTheme.labelSmall),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Suggested order: fewer past pickups and no missed pickups first — not who tapped fastest.',
                    style: TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
                  ),
                ],
                const SizedBox(height: 8),
                if (claimsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: green500)),
                  )
                else if (claimsAsync.hasError && !claimsAsync.hasValue)
                  Text('${claimsAsync.error}', style: const TextStyle(color: kErrorText))
                else if (claims.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No claims yet. Receivers nearby can claim this listing.',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  )
                else
                  Column(
                    children: claims.map((c) => _ClaimCard(
                      claim: c,
                      busy: _actionClaimId == c.id,
                      onApprove: c.status == ClaimStatus.pending ? () => _approve(c.id) : null,
                      onReject: c.status == ClaimStatus.pending ? () => _reject(c.id) : null,
                      onNoShow: c.status == ClaimStatus.approved ? () => _markNoShow(c) : null,
                    )).toList(),
                  ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${pending.length} pending — approve one receiver to reserve this food.',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: canConfirmPickup
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: PrimaryButton(
                      label: 'Confirm pickup',
                      isLoading: _actionClaimId == approvedClaim.id,
                      onPressed: () => _confirmPickup(approvedClaim),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.busy,
    this.onApprove,
    this.onReject,
    this.onNoShow,
  });

  final ClaimModel claim;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) {
    final name = claim.receiverName ?? 'Receiver';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (claim.status == ClaimStatus.pending && claim.priorityRank == 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: green100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Suggested first',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: green500),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: green100,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: green500, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      'Claimed ${_relativeTime(claim.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                    if (claim.status == ClaimStatus.pending &&
                        (claim.receiverPickups != null || claim.receiverNoShows != null))
                      Text(
                        '${claim.receiverPickups ?? 0} pickups · ${claim.receiverNoShows ?? 0} missed',
                        style: const TextStyle(fontSize: 11, color: kTextDisabled),
                      ),
                  ],
                ),
              ),
              if (claim.priorityRank != null && claim.status == ClaimStatus.pending)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gray100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '#${claim.priorityRank}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextSecondary),
                  ),
                ),
              StatusBadge.claim(claim.status),
            ],
          ),
          if (claim.pickupCode != null && claim.status == ClaimStatus.approved) ...[
            const SizedBox(height: 10),
            PickupCodeChip(code: claim.pickupCode!, label: 'Receiver should show this code'),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: green500),
                    onPressed: busy ? null : onApprove,
                    child: Text(busy ? 'Approving…' : 'Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (onNoShow != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: busy ? null : onNoShow,
              child: const Text(
                'Did not show up',
                style: TextStyle(color: kErrorText, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

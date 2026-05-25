import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/listing.dart';
import '../utils/format.dart';
import 'status_badge.dart';

/// Recent listing card — matches donor home mockup layout.
class DonorHomeListingCard extends StatelessWidget {
  const DonorHomeListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onMenu,
  });

  final ListingModel listing;
  final VoidCallback? onTap;
  final void Function(String action)? onMenu;

  @override
  Widget build(BuildContext context) {
    final description = listing.description?.trim();
    final snippet = description != null && description.isNotEmpty
        ? description
        : 'Delicious surplus food — ready for pickup nearby.';
    final location = listing.pickupLocationLabel ?? 'Pickup location';

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder.withValues(alpha: 0.65)),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodImage(url: listing.imageUrl),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              formatListingTitle(listing.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (onMenu != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  iconSize: 20,
                                  icon: const Icon(Icons.more_vert, color: kTextDisabled, size: 20),
                                  onSelected: onMenu,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'view', child: Text('View details')),
                                    PopupMenuItem(value: 'listings', child: Text('All listings')),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge.listing(listing.status),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: kTextSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(icon: Icons.place_outlined, label: location),
                      const SizedBox(height: 3),
                      _MetaRow(
                        icon: Icons.schedule_outlined,
                        label: formatListingDeadline(
                          status: listing.status,
                          deadline: listing.pickupDeadline,
                        ),
                        valueColor: listingDeadlineColor(
                          status: listing.status,
                          deadline: listing.pickupDeadline,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _MetaRow(
                        icon: Icons.groups_outlined,
                        label: formatFeedsLabel(listing.quantity),
                      ),
                    ],
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

class _FoodImage extends StatelessWidget {
  const _FoodImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 88,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : Container(
                color: green100,
                child: const Icon(Icons.restaurant_rounded, color: green500, size: 36),
              ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, this.valueColor});

  final IconData icon;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: kTextDisabled),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: valueColor ?? kTextSecondary, height: 1.2),
          ),
        ),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/listing.dart';
import '../utils/format.dart';
import 'status_badge.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onClaim,
    this.showClaimButton = true,
  });

  final ListingModel listing;
  final VoidCallback? onTap;
  final VoidCallback? onClaim;
  final bool showClaimButton;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(imageUrl: listing.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatListingTitle(listing.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusBadge.listing(listing.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          formatDistanceKm(listing.distanceKm),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: listingDeadlineColor(
                            status: listing.status,
                            deadline: listing.pickupDeadline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatListingDeadline(
                            status: listing.status,
                            deadline: listing.pickupDeadline,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: listingDeadlineColor(
                                  status: listing.status,
                                  deadline: listing.pickupDeadline,
                                ),
                              ),
                        ),
                      ],
                    ),
                    if (listing.donorVerified == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: green500),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: green500),
                          ),
                          if (listing.listedToday == true) ...[
                            const SizedBox(width: 8),
                            Text('· Listed today', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ],
                    if (showClaimButton && onClaim != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: onClaim,
                          style: FilledButton.styleFrom(
                            backgroundColor: green500,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Claim food'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
            : Container(
                color: gray100,
                child: const Icon(Icons.restaurant, color: kTextDisabled),
              ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/listing.dart';
import '../utils/format.dart';
import 'status_badge.dart';

/// Compact donor listing row for home / my listings.
class DonorListingTile extends StatelessWidget {
  const DonorListingTile({
    super.key,
    required this.listing,
    this.onTap,
  });

  final ListingModel listing;
  final VoidCallback? onTap;

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
              BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              _Thumb(url: listing.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatListingTitle(listing.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          listing.quantity,
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        const Text(' · ', style: TextStyle(color: kTextDisabled)),
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: listingDeadlineColor(
                            status: listing.status,
                            deadline: listing.pickupDeadline,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          formatListingDeadline(
                            status: listing.status,
                            deadline: listing.pickupDeadline,
                          ),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.listing(listing.status),
              const Icon(Icons.chevron_right, color: kTextDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : Container(
                color: green100,
                child: const Icon(Icons.restaurant_rounded, color: green500, size: 26),
              ),
      ),
    );
  }
}

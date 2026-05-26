import '../models/claim.dart';
import '../models/enums.dart';
import '../models/listing.dart';

/// Latest claim by this user for a listing (any status).
ClaimModel? findMyClaimForListing(List<ClaimModel> claims, String listingId) {
  final mine = claims.where((c) => c.listingId == listingId).toList();
  if (mine.isEmpty) return null;
  mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return mine.first;
}

/// Bottom bar label + whether the user can submit a new claim.
({String label, bool canSubmit}) claimActionForListing({
  required ListingModel listing,
  ClaimModel? myClaim,
}) {
  if (myClaim != null) {
    switch (myClaim.status) {
      case ClaimStatus.pending:
        return (label: 'Claim pending', canSubmit: false);
      case ClaimStatus.approved:
        return (label: 'Approved — see Claims tab', canSubmit: false);
      case ClaimStatus.rejected:
        break;
      case ClaimStatus.collected:
        return (label: 'Pickup completed', canSubmit: false);
    }
  }

  if (listing.status != ListingStatus.available) {
    if (listing.status == ListingStatus.claimed) {
      return (label: 'Already claimed', canSubmit: false);
    }
    if (listing.status == ListingStatus.completed) {
      return (label: 'Listing completed', canSubmit: false);
    }
    return (label: 'Not available', canSubmit: false);
  }

  if (myClaim?.status == ClaimStatus.rejected) {
    return (label: 'Request claim again', canSubmit: true);
  }

  return (label: 'Request claim', canSubmit: true);
}

/// Short label for list cards.
String? foodCardClaimLabel({
  required ListingModel listing,
  ClaimModel? myClaim,
}) {
  final action = claimActionForListing(listing: listing, myClaim: myClaim);
  if (action.canSubmit) return null;
  if (myClaim?.status == ClaimStatus.pending) return 'Pending';
  if (myClaim?.status == ClaimStatus.approved) return 'Approved';
  if (myClaim?.status == ClaimStatus.collected) return 'Completed';
  if (myClaim?.status == ClaimStatus.rejected) return 'Declined';
  if (listing.status == ListingStatus.claimed) return 'Claimed';
  return null;
}

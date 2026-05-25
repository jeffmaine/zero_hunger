import 'package:go_router/go_router.dart';

import '../models/enums.dart';

/// Navigate from FCM data payload (matches backend notification types).
void navigateFromPushData(
  GoRouter router, {
  required UserRole? role,
  required Map<String, dynamic> data,
}) {
  final type = data['type'] as String?;
  final listingId = data['listing_id'] as String?;

  switch (type) {
    case 'claim_received':
      if (listingId != null && listingId.isNotEmpty) {
        router.push('/donor/listing/$listingId');
      } else if (role == UserRole.donor) {
        router.go('/donor/listings');
      }
      break;
    case 'claim_approved':
    case 'claim_rejected':
      if (role == UserRole.donor) {
        router.go('/donor/listings');
      } else {
        router.go('/receiver/claims');
      }
      break;
    case 'listing_expiring':
      if (listingId != null && listingId.isNotEmpty) {
        if (role == UserRole.donor) {
          router.push('/donor/listing/$listingId');
        } else {
          router.push('/receiver/food/$listingId');
        }
      }
      break;
    default:
      router.push('/notifications');
  }
}

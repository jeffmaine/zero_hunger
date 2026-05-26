import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'claims_provider.dart';
import 'donor_dashboard_provider.dart';
import 'listings_provider.dart';
import 'notifications_provider.dart';
import 'profile_provider.dart';

/// Drop cached authenticated API data after sign-out.
void invalidateSessionProviders(WidgetRef ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(myClaimsProvider);
  ref.invalidate(claimLimitsProvider);
  ref.invalidate(listingClaimsProvider);
  ref.invalidate(donorDashboardProvider);
  ref.invalidate(nearbyListingsProvider);
  ref.invalidate(mapPinsProvider);
  ref.invalidate(myListingsProvider);
  ref.invalidate(listingDetailProvider);
}

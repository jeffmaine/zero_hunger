import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';

final myClaimsProvider = FutureProvider.autoDispose<List<ClaimModel>>((ref) async {
  return ref.watch(claimServiceProvider).fetchMyClaims();
});

final claimLimitsProvider = FutureProvider.autoDispose<ClaimLimitsModel>((ref) async {
  return ref.watch(claimServiceProvider).fetchLimits();
});

final listingClaimsProvider =
    FutureProvider.autoDispose.family<List<ClaimModel>, String>((ref, listingId) async {
  return ref.watch(claimServiceProvider).fetchForListing(listingId);
});

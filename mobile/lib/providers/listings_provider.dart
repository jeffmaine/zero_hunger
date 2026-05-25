import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';
import 'auth_provider.dart';
import 'geo_provider.dart';

/// Resolves lat/lng from device geo state, then user profile — never mutates geo here.
({double lat, double lng})? _resolveCoords(Ref ref) {
  final geo = ref.watch(geoProvider);
  if (geo.hasCoords) {
    return (lat: geo.latitude!, lng: geo.longitude!);
  }
  final user = ref.watch(authProvider).user;
  if (user?.latitude != null && user?.longitude != null) {
    return (lat: user!.latitude!, lng: user.longitude!);
  }
  return null;
}

final nearbyListingsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final geo = ref.watch(geoProvider);
  final category = ref.watch(selectedCategoryProvider);
  final coords = _resolveCoords(ref);
  if (coords == null) return [];

  final service = ref.watch(listingServiceProvider);
  return service.fetchNearby(
    lat: coords.lat,
    lng: coords.lng,
    radiusKm: geo.radiusKm,
    category: category,
  );
});

final mapPinsProvider = FutureProvider.autoDispose<List<MapPinModel>>((ref) async {
  final geo = ref.watch(geoProvider);
  final coords = _resolveCoords(ref);
  if (coords == null) return [];

  return ref.watch(listingServiceProvider).fetchMapPins(
    lat: coords.lat,
    lng: coords.lng,
    radiusKm: geo.radiusKm,
  );
});

final myListingsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  return ref.watch(listingServiceProvider).fetchMine();
});

final listingDetailProvider =
    FutureProvider.autoDispose.family<ListingModel, String>((ref, id) async {
  return ref.watch(listingServiceProvider).fetchById(id);
});

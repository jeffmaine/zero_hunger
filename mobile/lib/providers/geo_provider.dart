import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import '../services/token_storage.dart';
import 'auth_provider.dart';

/// How the user chose the map/feed search center.
enum LocationSource { gps, manual, hybrid }

class GeoState {
  const GeoState({
    this.deviceLatitude,
    this.deviceLongitude,
    this.searchLatitude,
    this.searchLongitude,
    this.label,
    this.radiusKm = 5,
    this.source = LocationSource.gps,
    this.isLoading = false,
    this.error,
  });

  final double? deviceLatitude;
  final double? deviceLongitude;
  final double? searchLatitude;
  final double? searchLongitude;
  final String? label;
  final double radiusKm;
  final LocationSource source;
  final bool isLoading;
  final String? error;

  double? get latitude => searchLatitude ?? deviceLatitude;
  double? get longitude => searchLongitude ?? deviceLongitude;

  bool get hasCoords => latitude != null && longitude != null;

  GeoState copyWith({
    double? deviceLatitude,
    double? deviceLongitude,
    double? searchLatitude,
    double? searchLongitude,
    String? label,
    double? radiusKm,
    LocationSource? source,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return GeoState(
      deviceLatitude: deviceLatitude ?? this.deviceLatitude,
      deviceLongitude: deviceLongitude ?? this.deviceLongitude,
      searchLatitude: clearSearch ? null : (searchLatitude ?? this.searchLatitude),
      searchLongitude: clearSearch ? null : (searchLongitude ?? this.searchLongitude),
      label: label ?? this.label,
      radiusKm: radiusKm ?? this.radiusKm,
      source: source ?? this.source,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final geoProvider = StateNotifierProvider<GeoNotifier, GeoState>((ref) {
  return GeoNotifier(
    ref.watch(locationServiceProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authProvider.notifier),
  );
});

class GeoNotifier extends StateNotifier<GeoState> {
  GeoNotifier(this._location, this._storage, this._authNotifier) : super(const GeoState()) {
    _hydrateFromUser();
  }

  final LocationService _location;
  final TokenStorage _storage;
  final AuthNotifier _authNotifier;

  void _hydrateFromUser() {
    final user = _authNotifier.state.user;
    if (user?.latitude != null && user?.longitude != null) {
      state = state.copyWith(
        searchLatitude: user!.latitude,
        searchLongitude: user.longitude,
        label: user.locationLabel ?? state.label,
        source: LocationSource.hybrid,
      );
    }
  }

  Future<void> ensureLocation() async {
    if (state.hasCoords && state.deviceLatitude != null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final savedLabel = await _storage.locationLabel();
    final userLabel = _authNotifier.state.user?.locationLabel;
    final pos = await _location.getCurrentPosition();
    if (pos == null) {
      final user = _authNotifier.state.user;
      if (user?.latitude != null && user?.longitude != null) {
        state = state.copyWith(
          searchLatitude: user!.latitude,
          searchLongitude: user.longitude,
          label: savedLabel ?? userLabel ?? user.locationLabel ?? 'Saved area',
          isLoading: false,
          source: LocationSource.hybrid,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Location permission needed to find food nearby.',
        label: savedLabel ?? userLabel ?? 'Set location',
      );
      return;
    }
    final label = savedLabel ?? userLabel ?? 'Near you';
    state = state.copyWith(
      deviceLatitude: pos.latitude,
      deviceLongitude: pos.longitude,
      searchLatitude: state.searchLatitude ?? pos.latitude,
      searchLongitude: state.searchLongitude ?? pos.longitude,
      label: label,
      isLoading: false,
      source: state.source == LocationSource.manual ? LocationSource.manual : LocationSource.gps,
    );
    if (state.source != LocationSource.manual) {
      try {
        final user = await _location.syncToServer(
          latitude: pos.latitude,
          longitude: pos.longitude,
          label: state.label,
          source: 'gps',
        );
        _authNotifier.setUser(user);
      } catch (_) {}
    }
  }

  Future<void> useCurrentLocation({bool syncProfile = false}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSearch: true);
    final pos = await _location.getCurrentPosition();
    if (pos == null) {
      state = state.copyWith(isLoading: false, error: 'Could not get GPS location');
      return;
    }
    state = state.copyWith(
      deviceLatitude: pos.latitude,
      deviceLongitude: pos.longitude,
      searchLatitude: pos.latitude,
      searchLongitude: pos.longitude,
      label: 'Current location',
      source: LocationSource.gps,
      isLoading: false,
    );
    if (syncProfile) {
      try {
        final user = await _location.syncToServer(
          latitude: pos.latitude,
          longitude: pos.longitude,
          label: 'Current location',
          source: 'gps',
        );
        _authNotifier.setUser(user);
        await _storage.setLocationLabel('Current location');
      } catch (_) {}
    }
  }

  void setSearchCenter({
    required double lat,
    required double lng,
    required String label,
    LocationSource source = LocationSource.manual,
  }) {
    state = state.copyWith(
      searchLatitude: lat,
      searchLongitude: lng,
      label: label,
      source: source,
    );
  }

  Future<void> geocodeAndSetCenter(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'No results for that place');
        return;
      }
      final loc = locations.first;
      setSearchCenter(
        lat: loc.latitude,
        lng: loc.longitude,
        label: query.trim(),
        source: LocationSource.manual,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Could not find that place');
    }
  }

  Future<void> saveSearchAsProfile() async {
    final lat = state.latitude;
    final lng = state.longitude;
    if (lat == null || lng == null) return;
    try {
      final user = await _location.syncToServer(
        latitude: lat,
        longitude: lng,
        label: state.label ?? 'My area',
        source: state.source == LocationSource.gps ? 'gps' : 'manual',
      );
      _authNotifier.setUser(user);
      if (state.label != null) await _storage.setLocationLabel(state.label!);
    } catch (_) {}
  }

  void setRadius(double km) {
    state = state.copyWith(radiusKm: km);
  }
}

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

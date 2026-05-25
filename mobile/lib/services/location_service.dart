import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'token_storage.dart';

class GeoPosition {
  GeoPosition({required this.latitude, required this.longitude, this.label});
  final double latitude;
  final double longitude;
  final String? label;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    ref.watch(apiServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

class LocationService {
  LocationService(this._api, this._storage);

  final ApiService _api;
  final TokenStorage _storage;

  Future<GeoPosition?> getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw StateError('Location timed out'),
    );
    return GeoPosition(latitude: pos.latitude, longitude: pos.longitude);
  }

  Future<UserModel> syncToServer({
    required double latitude,
    required double longitude,
    String? label,
    String source = 'gps',
  }) async {
    try {
      final res = await _api.dio.patch(
        '/auth/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (label != null) 'label': label,
          'source': source,
        },
      );
      if (label != null) await _storage.setLocationLabel(label);
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}

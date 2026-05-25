import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/donor_dashboard.dart';
import '../services/donor_dashboard_service.dart';
import 'auth_provider.dart';
import 'geo_provider.dart';

final donorDashboardProvider = FutureProvider.autoDispose<DonorDashboardModel>((ref) async {
  final geo = ref.watch(geoProvider);
  final user = ref.watch(authProvider).user;

  double? lat = geo.latitude;
  double? lng = geo.longitude;
  if (lat == null || lng == null) {
    lat = user?.latitude;
    lng = user?.longitude;
  }

  return ref.watch(donorDashboardServiceProvider).fetchDashboard(
        lat: lat,
        lng: lng,
        radiusKm: geo.radiusKm,
      );
});

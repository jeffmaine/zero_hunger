import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/donor_dashboard.dart';
import 'api_service.dart';

final donorDashboardServiceProvider = Provider<DonorDashboardService>((ref) {
  return DonorDashboardService(ref.watch(apiServiceProvider));
});

class DonorDashboardService {
  DonorDashboardService(this._api);

  final ApiService _api;

  Future<DonorDashboardModel> fetchDashboard({
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) async {
    try {
      final res = await _api.dio.get(
        '/donors/me/dashboard',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          'radius': radiusKm,
        },
      );
      return DonorDashboardModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claim.dart';
import 'api_service.dart';

final claimServiceProvider = Provider<ClaimService>((ref) {
  return ClaimService(ref.watch(apiServiceProvider));
});

class ClaimService {
  ClaimService(this._api);

  final ApiService _api;

  Future<List<ClaimModel>> fetchMyClaims() async {
    try {
      final res = await _api.dio.get('/claims');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimModel> createClaim(String listingId) async {
    try {
      final res = await _api.dio.post(
        '/claims',
        data: {'listing_id': listingId},
      );
      return ClaimModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<List<ClaimModel>> fetchForListing(String listingId) async {
    try {
      final res = await _api.dio.get('/claims/listing/$listingId');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimModel> approveClaim(String claimId) async {
    try {
      final res = await _api.dio.put('/claims/$claimId/approve');
      return ClaimModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimLimitsModel> fetchLimits() async {
    try {
      final res = await _api.dio.get('/claims/limits');
      return ClaimLimitsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimModel> collectClaim(String claimId, String pickupCode) async {
    try {
      final res = await _api.dio.post(
        '/claims/$claimId/collect',
        data: {'pickup_code': pickupCode},
      );
      return ClaimModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimModel> rejectClaim(String claimId) async {
    try {
      final res = await _api.dio.put('/claims/$claimId/reject');
      return ClaimModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ClaimModel> markNoShow(String claimId) async {
    try {
      final res = await _api.dio.post('/claims/$claimId/no-show');
      return ClaimModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/listing.dart';
import 'api_service.dart';

final listingServiceProvider = Provider<ListingService>((ref) {
  return ListingService(ref.watch(apiServiceProvider));
});

class ListingService {
  ListingService(this._api);

  final ApiService _api;

  Future<List<ListingModel>> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? category,
  }) async {
    try {
      final res = await _api.dio.get(
        '/listings',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          if (category != null) 'category': category,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final list = data['listings'] as List<dynamic>? ?? [];
      return list
          .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<List<MapPinModel>> fetchMapPins({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final res = await _api.dio.get(
        '/listings/map',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusKm},
      );
      final data = res.data as Map<String, dynamic>;
      final pins = data['pins'] as List<dynamic>? ?? [];
      return pins
          .map((e) => MapPinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ListingModel> fetchById(String id) async {
    try {
      final res = await _api.dio.get('/listings/$id');
      return ListingModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<List<ListingModel>> fetchMine() async {
    try {
      final res = await _api.dio.get('/listings/mine');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ListingModel> create(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/listings', data: body);
      return ListingModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ListingModel> patchStatus(String listingId, ListingStatus status) async {
    try {
      final res = await _api.dio.patch(
        '/listings/$listingId/status',
        data: {'status': status.name},
      );
      return ListingModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _api.dio.post('/listings/upload-image', data: form);
      return (res.data as Map<String, dynamic>)['image_url'] as String;
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<ListingModel> update(String listingId, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.put('/listings/$listingId', data: body);
      return ListingModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _api.dio.delete('/listings/$listingId');
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}

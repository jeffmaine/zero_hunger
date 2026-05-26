import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'token_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiServiceProvider), ref.watch(tokenStorageProvider));
});

class AuthService {
  AuthService(this._api, this._storage);

  final ApiService _api;
  final TokenStorage _storage;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await _api.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role.apiValue,
          'phone': phone,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      await _saveTokens(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _saveTokens(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<UserModel?> fetchMe({Duration? timeout}) async {
    try {
      final options = timeout != null
          ? Options(sendTimeout: timeout, receiveTimeout: timeout)
          : null;
      final request = _api.dio.get('/auth/me', options: options);
      final res = timeout != null
          ? await request.timeout(timeout)
          : await request;
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> logout() => _storage.clearTokens();

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.saveTokens(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }
}

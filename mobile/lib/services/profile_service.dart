import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import 'api_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(apiServiceProvider));
});

class ProfileService {
  ProfileService(this._api);

  final ApiService _api;

  Future<UserModel> fetchProfile() async {
    try {
      final res = await _api.dio.get('/users/me/profile');
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.patch('/users/me', data: body);
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> updateFcmToken(String? token) async {
    try {
      await _api.dio.put('/users/me/fcm-token', data: {'token': token});
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _api.dio.post('/users/me/avatar', data: form);
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}

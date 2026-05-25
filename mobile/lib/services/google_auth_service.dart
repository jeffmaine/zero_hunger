import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants.dart';
import '../models/enums.dart';
import 'api_service.dart';
import 'token_storage.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(
    ref.watch(apiServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Mobile Google Sign-In → `POST /oauth/google/mobile` with ID token.
class GoogleAuthService {
  GoogleAuthService(this._api, this._storage);

  final ApiService _api;
  final TokenStorage _storage;

  GoogleSignIn get _googleSignIn => GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: googleServerClientId.isNotEmpty ? googleServerClientId : null,
      );

  Future<void> signInAndExchange({
    required UserRole role,
    String phone = '',
  }) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw ApiException('Google sign-in was cancelled');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          'Could not get Google token. Set GOOGLE_SERVER_CLIENT_ID (Web client) in constants.dart for Android.',
        );
      }

      final res = await _api.dio.post(
        '/oauth/google/mobile',
        data: {
          'id_token': idToken,
          'role': role.apiValue,
          'phone': phone,
        },
      );
      final data = res.data as Map<String, dynamic>;
      await _storage.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      String? code;
      final body = e.response?.data;
      if (body is Map) {
        final details = body['details'];
        if (details is Map && details['code'] is String) {
          code = details['code'] as String;
        }
      }
      if (code == 'GOOGLE_NOT_CONFIGURED') {
        throw ApiException('Google sign-in is not configured on the server yet (GOOGLE_CLIENT_ID in backend .env).');
      }
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}

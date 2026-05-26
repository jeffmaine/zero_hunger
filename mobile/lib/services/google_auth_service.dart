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
        serverClientId: isGoogleSignInConfigured ? googleWebClientId : null,
      );

  void _ensureClientConfigured() {
    if (!isGoogleSignInConfigured) {
      throw ApiException(
        'Google Sign-In is not set up on this build.\n\n'
        '1. Google Cloud → Credentials → create a Web OAuth client\n'
        '2. backend/.env: GOOGLE_CLIENT_ID=<that Web client ID>\n'
        '3. mobile: set kGoogleWebClientIdFallback in lib/core/constants.dart '
        '   OR flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web client ID>\n'
        '4. Android: add SHA-1 + package com.zerohunger.zero_hunger to an Android OAuth client\n\n'
        'See mobile/GOOGLE_SIGNIN.md',
      );
    }
  }

  Future<void> signInAndExchange({
    required UserRole role,
    String phone = '',
  }) async {
    _ensureClientConfigured();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw ApiException('Google sign-in was cancelled');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          'Google did not return an ID token. On Android, confirm:\n'
          '• Web client ID is set (constants or --dart-define)\n'
          '• SHA-1 of your debug keystore is in Google Cloud (Android OAuth client)\n'
          '• Package name: com.zerohunger.zero_hunger',
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
        throw ApiException(
          'Server: Google OAuth is not configured. Set GOOGLE_CLIENT_ID in backend/.env '
          '(Web client ID) and restart the API — on EC2: edit .env then docker compose up -d --build.',
        );
      }
      if (code == 'INVALID_GOOGLE_TOKEN') {
        throw ApiException(
          'Server rejected the Google token. Use the same Web client ID in:\n'
          '• backend GOOGLE_CLIENT_ID\n'
          '• mobile googleWebClientId / GOOGLE_SERVER_CLIENT_ID',
        );
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/token_storage.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isBootstrapping = true,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isBootstrapping;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isBootstrapping,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(googleAuthServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth, this._googleAuth, this._storage) : super(const AuthState()) {
    bootstrap();
  }

  final AuthService _auth;
  final GoogleAuthService _googleAuth;
  final TokenStorage _storage;

  Future<void> bootstrap() async {
    state = state.copyWith(isBootstrapping: true);
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isBootstrapping: false, clearUser: true);
      return;
    }
    try {
      final user = await _auth.fetchMe();
      state = state.copyWith(user: user, isBootstrapping: false, clearUser: user == null);
    } catch (_) {
      await _storage.clearTokens();
      state = state.copyWith(isBootstrapping: false, clearUser: true);
    }
  }

  Future<UserModel?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.login(email: email, password: password);
      final user = await _auth.fetchMe();
      if (user == null) {
        throw ApiException('Login succeeded but session could not be loaded. Try again.');
      }
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      final message = e is ApiException ? e.message : 'Login failed: $e';
      state = state.copyWith(isLoading: false, error: message);
      throw ApiException(message);
    }
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
      );
      await _storage.setOnboarded(true);
      final user = await _auth.fetchMe();
      if (user == null) {
        throw ApiException(
          'Account created but sign-in could not be completed. Try logging in.',
        );
      }
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      final message = e is ApiException ? e.message : 'Registration failed: $e';
      state = state.copyWith(isLoading: false, error: message);
      throw ApiException(message);
    }
  }

  Future<UserModel?> signInWithGoogle({
    required UserRole role,
    String phone = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _googleAuth.signInAndExchange(role: role, phone: phone);
      await _storage.setOnboarded(true);
      final user = await _auth.fetchMe();
      if (user == null) {
        throw ApiException('Google sign-in succeeded but session could not be loaded.');
      }
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      final message = e is ApiException ? e.message : 'Google sign-in failed: $e';
      state = state.copyWith(isLoading: false, error: message);
      throw ApiException(message);
    }
  }

  Future<void> logout() async {
    await _googleAuth.signOutGoogle();
    await _auth.logout();
    state = state.copyWith(clearUser: true);
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

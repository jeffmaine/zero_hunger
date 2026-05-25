import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final prefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _onboardedKey = 'has_onboarded';
  static const _pendingRoleKey = 'pending_role';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _secure.write(key: _accessKey, value: access);
    await _secure.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccessToken() => _secure.read(key: _accessKey);

  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);

  Future<void> clearTokens() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }

  Future<bool> hasOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_onboardedKey) ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardedKey, value);
  }

  Future<String?> pendingRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_pendingRoleKey);
  }

  Future<void> setPendingRole(String? role) async {
    final p = await SharedPreferences.getInstance();
    if (role == null) {
      await p.remove(_pendingRoleKey);
    } else {
      await p.setString(_pendingRoleKey, role);
    }
  }

  Future<String?> locationLabel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('location_label');
  }

  Future<void> setLocationLabel(String? label) async {
    final p = await SharedPreferences.getInstance();
    if (label == null) {
      await p.remove('location_label');
    } else {
      await p.setString('location_label', label);
    }
  }
}

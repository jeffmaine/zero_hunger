import 'dart:io';

import 'package:flutter/foundation.dart';

/// Ngrok tunnel to local API (same URL works on emulator + physical device).
/// Set to empty string to use local host URLs instead.
const String kNgrokApiBase = 'https://collene-pentagrid-krishna.ngrok-free.dev/api/v1';

/// API base URL for the mobile app.
///
/// Priority: `API_BASE` dart-define → [kNgrokApiBase] (if set) → platform localhost.
///
/// Local without ngrok:
///   `flutter run --dart-define=API_BASE=`
///   or clear [kNgrokApiBase] below.
///
/// Override ngrok:
///   `flutter run --dart-define=API_BASE=https://your-tunnel.ngrok-free.dev/api/v1`
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kNgrokApiBase.isNotEmpty) return kNgrokApiBase;
  if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
  return 'http://127.0.0.1:8000/api/v1';
}

bool get usesNgrok => apiBaseUrl.contains('ngrok');

/// Google OAuth **Web client** ID (for Android id_token). Pass via:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Enable Firebase Cloud Messaging after `flutterfire configure`:
/// `flutter run --dart-define=ENABLE_FCM=true`
const bool enableFcm = bool.fromEnvironment('ENABLE_FCM', defaultValue: false);

const double defaultRadiusKm = 5;
const List<double> radiusOptionsKm = [2, 5, 10];

class CategoryOption {
  const CategoryOption({required this.apiValue, required this.label});
  final String? apiValue;
  final String label;
}

const List<CategoryOption> categoryOptions = [
  CategoryOption(apiValue: null, label: 'All'),
  CategoryOption(apiValue: 'cooked_meal', label: 'Cooked'),
  CategoryOption(apiValue: 'groceries', label: 'Groceries'),
  CategoryOption(apiValue: 'baked_goods', label: 'Baked'),
  CategoryOption(apiValue: 'fruits', label: 'Fruits'),
  CategoryOption(apiValue: 'beverages', label: 'Drinks'),
];

const Map<String, String> roleLabels = {
  'donor': 'Donor',
  'receiver': 'Receiver',
  'volunteer': 'Volunteer',
};

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Optional ngrok tunnel for local dev. Leave empty when using EC2 or localhost.
const String kNgrokApiBase = '';

/// Deployed API (EC2). Used on phones when [API_BASE] dart-define is not set.
const String kDeployedApiBase = 'http://3.251.66.229:8000/api/v1';

/// API base URL for the mobile app.
///
/// Priority: `API_BASE` dart-define → [kNgrokApiBase] → [kDeployedApiBase] → localhost.
///
/// Examples:
///   `flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1`  # Android emulator → local API
///   `flutter run --dart-define=API_BASE=http://127.0.0.1:8000/api/v1` # iOS simulator → local API
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kNgrokApiBase.isNotEmpty) return kNgrokApiBase;
  if (kDeployedApiBase.isNotEmpty) return kDeployedApiBase;
  if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
  return 'http://127.0.0.1:8000/api/v1';
}

bool get usesNgrok => apiBaseUrl.contains('ngrok');

/// Paste your Google **Web application** OAuth client ID for local runs (optional).
/// Same value as `GOOGLE_CLIENT_ID` in backend `.env`. Or pass via dart-define (overrides this).
/// Google Cloud → APIs & Services → Credentials → OAuth 2.0 → Web client
const String kGoogleWebClientIdFallback = '';

/// Web client ID — required on Android for `idToken`. See `mobile/GOOGLE_SIGNIN.md`.
String get googleWebClientId {
  const fromEnv = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  if (fromEnv.isNotEmpty) return fromEnv;
  return kGoogleWebClientIdFallback;
}

bool get isGoogleSignInConfigured => googleWebClientId.isNotEmpty;

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

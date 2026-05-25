import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/router.dart';
import '../firebase_options.dart';
import '../providers/auth_provider.dart';
import '../providers/claims_provider.dart';
import '../providers/donor_dashboard_provider.dart';
import '../providers/notifications_provider.dart';
import '../utils/push_navigation.dart';
import 'profile_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!enableFcm) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM] background: ${message.notification?.title}');
  }
}

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  Future<void> setup() async {
    if (!enableFcm || _initialized) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      messaging.onTokenRefresh.listen((_) => registerTokenIfPossible());

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _scheduleNavigation(initial);
      }

      _initialized = true;
      await registerTokenIfPossible();
      if (kDebugMode) debugPrint('[FCM] initialized');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] setup skipped: $e\n$st');
      }
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    _ref.invalidate(unreadNotificationsProvider);
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(donorDashboardProvider);
    _ref.invalidate(myClaimsProvider);
    if (kDebugMode) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    _scheduleNavigation(message);
  }

  void _scheduleNavigation(RemoteMessage message) {
    Future.microtask(() {
      final router = _ref.read(routerProvider);
      final role = _ref.read(authProvider).user?.role;
      navigateFromPushData(router, role: role, data: message.data);
    });
  }

  Future<void> registerTokenIfPossible() async {
    if (!enableFcm || !_initialized) return;
    if (!_ref.read(authProvider).isAuthenticated) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _ref.read(profileServiceProvider).updateFcmToken(token);
      if (kDebugMode) debugPrint('[FCM] token registered');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] token register failed: $e');
    }
  }

  Future<void> clearToken() async {
    if (!enableFcm) return;
    try {
      await _ref.read(profileServiceProvider).updateFcmToken(null);
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] clear token: $e');
    }
  }
}

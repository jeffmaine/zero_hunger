import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'services/fcm_service.dart';

class ZeroHungerApp extends ConsumerStatefulWidget {
  const ZeroHungerApp({super.key});

  @override
  ConsumerState<ZeroHungerApp> createState() => _ZeroHungerAppState();
}

class _ZeroHungerAppState extends ConsumerState<ZeroHungerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).setup();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final fcm = ref.read(fcmServiceProvider);
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        fcm.registerTokenIfPossible();
      }
      if (!next.isAuthenticated && (prev?.isAuthenticated ?? false)) {
        fcm.clearToken();
      }
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Zero Hunger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}

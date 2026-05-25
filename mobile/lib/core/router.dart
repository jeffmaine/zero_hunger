import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/donor/create_listing_screen.dart';
import '../screens/donor/donor_listing_detail_screen.dart';
import '../screens/home/food_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/shells/donor_shell.dart';
import '../screens/shells/receiver_shell.dart';
import '../screens/splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Single GoRouter instance — do NOT [ref.watch] auth here or every [setUser]
/// recreates the router and resets the donor shell to Home.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register' || path == '/onboarding';
      final isSplash = path == '/';

      if (auth.isBootstrapping) {
        return isSplash ? null : '/';
      }
      if (!auth.isAuthenticated) {
        if (isAuthRoute || isSplash) return null;
        return '/login';
      }
      if (isAuthRoute || isSplash) {
        final role = auth.user?.role;
        return role?.name == 'donor' ? '/donor' : '/receiver';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ReceiverShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/receiver', builder: (_, __) => receiverTabScreens()[0]),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/receiver/map', builder: (_, __) => receiverTabScreens()[1]),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/receiver/claims', builder: (_, __) => receiverTabScreens()[2]),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/receiver/profile', builder: (_, __) => receiverTabScreens()[3]),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/receiver/food/:id',
        builder: (_, state) => FoodDetailScreen(listingId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => DonorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/donor', builder: (_, __) => donorTabScreens()[0])]),
          StatefulShellBranch(routes: [GoRoute(path: '/donor/listings', builder: (_, __) => donorTabScreens()[1])]),
          StatefulShellBranch(routes: [GoRoute(path: '/donor/profile', builder: (_, __) => donorTabScreens()[2])]),
        ],
      ),
      GoRoute(path: '/donor/create', builder: (_, __) => const CreateListingScreen()),
      GoRoute(
        path: '/donor/listing/:id',
        builder: (_, state) => DonorListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Notifies GoRouter to re-run [redirect] on login/logout/bootstrap only.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(
      authProvider.select(
        (s) => '${s.isAuthenticated}|${s.isBootstrapping}|${s.user?.id}',
      ),
      (_, __) => notifyListeners(),
    );
  }
  final Ref _ref;
}

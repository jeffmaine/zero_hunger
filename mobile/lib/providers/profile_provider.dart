import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  if (!ref.read(authProvider).isAuthenticated) {
    throw StateError('signed_out');
  }
  final profile = await ref.read(profileServiceProvider).fetchProfile();
  // Sync auth for avatar/name elsewhere; router no longer watches auth so this won't reset tabs.
  ref.read(authProvider.notifier).setUser(profile);
  return profile;
});

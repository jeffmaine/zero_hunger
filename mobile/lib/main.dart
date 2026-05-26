import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[ZeroHunger] API base: $apiBaseUrl');
    if (!isGoogleSignInConfigured) {
      debugPrint(
        '[ZeroHunger] Google Sign-In: not configured — set kGoogleWebClientIdFallback or '
        'GOOGLE_SERVER_CLIENT_ID (see mobile/GOOGLE_SIGNIN.md)',
      );
    }
  }
  runApp(const ProviderScope(child: ZeroHungerApp()));
}

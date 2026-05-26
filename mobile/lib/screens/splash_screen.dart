import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../services/token_storage.dart';
import '../widgets/brand_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _brandingDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _brandingDone = true);
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (_navigated || !_brandingDone) return;
    final auth = ref.read(authProvider);
    if (auth.isBootstrapping) return;

    _navigated = true;
    if (auth.isAuthenticated && auth.user != null) {
      final role = auth.user!.role;
      context.go(role == UserRole.donor ? '/donor' : '/receiver');
      return;
    }
    ref.read(tokenStorageProvider).hasOnboarded().then((onboarded) {
      if (!mounted || !_navigated) return;
      context.go(onboarded ? '/login' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isBootstrapping == true && !next.isBootstrapping) {
        _tryNavigate();
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [green500, Color(0xFF1B4332)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(size: 72),
              const SizedBox(height: 16),
              Text(
                'Rescue food. Feed community.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

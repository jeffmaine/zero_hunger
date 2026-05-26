import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/token_storage.dart';
import '../utils/auth_navigation.dart';
import '../widgets/brand_logo.dart';
import '../widgets/splash_loading_indicator.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Minimum time on splash so intro + loader are visible (ms).
  static const int _minDisplayMs = 2600;

  bool _introComplete = false;
  bool _minTimeElapsed = false;
  bool _navigated = false;

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _loaderFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 1, curve: Curves.easeOut),
    );

    _introController.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _introComplete = true);
      _tryNavigate();
    });

    Future<void>.delayed(const Duration(milliseconds: _minDisplayMs), () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_navigated || !_introComplete || !_minTimeElapsed) return;
    final auth = ref.read(authProvider);
    if (auth.isBootstrapping) return;

    _navigated = true;
    if (auth.isAuthenticated && auth.user != null) {
      goAfterAuth(context, auth.user!);
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [green500, Color(0xFF1B4332), Color(0xFF0D2818)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _pulseController]),
              builder: (context, _) {
                final breathe = 1 + 0.035 * math.sin(_pulseController.value * 2 * math.pi);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SplashPulseRings(
                            progress: _pulseController.value,
                            color: Colors.white,
                            maxSize: 150,
                          ),
                          FadeTransition(
                            opacity: _logoFade,
                            child: Transform.scale(
                              scale: _logoScale.value * breathe,
                              child: const BrandLogo(size: 72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Text(
                          'Rescue food. Feed community.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _loaderFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SplashLoadingIndicator(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Loading…',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.55),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

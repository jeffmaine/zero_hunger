import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft bouncing dots for splash / loading on brand gradient.
class SplashLoadingIndicator extends StatefulWidget {
  const SplashLoadingIndicator({
    super.key,
    this.color = Colors.white,
    this.size = 8,
  });

  final Color color;
  final double size;

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index * 0.2) % 1.0;
            final lift = math.sin(phase * math.pi);
            final opacity = 0.35 + 0.65 * lift;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -6 * lift),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.35 * lift),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Expanding rings behind the logo — subtle “ripple” on splash.
class SplashPulseRings extends StatelessWidget {
  const SplashPulseRings({
    super.key,
    required this.progress,
    this.color = Colors.white,
    this.maxSize = 140,
  });

  final double progress;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: CustomPaint(
        painter: _PulseRingsPainter(progress: progress, color: color),
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  _PulseRingsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final ringPhase = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * (0.35 + 0.65 * ringPhase);
      final opacity = (1 - ringPhase) * 0.28;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

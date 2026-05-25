import 'package:flutter/material.dart';

import '../core/theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: kSurface,
          foregroundColor: kTextPrimary,
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: green500),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleLogoMark(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kTextDisabled),
          ),
        ),
        const Expanded(child: Divider(color: kBorder)),
      ],
    );
  }
}

/// Minimal multicolor G mark (no asset required).
class _GoogleLogoMark extends StatelessWidget {
  const _GoogleLogoMark({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    const stroke = 2.2;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1), -0.4, 1.2, false, _arcPaint(const Color(0xFF4285F4), stroke));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1), 0.9, 1.0, false, _arcPaint(const Color(0xFF34A853), stroke));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1), 2.0, 1.1, false, _arcPaint(const Color(0xFFFBBC05), stroke));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1), 3.2, 1.0, false, _arcPaint(const Color(0xFFEA4335), stroke));
    canvas.drawLine(c, Offset(size.width - 1, r), _arcPaint(const Color(0xFF4285F4), stroke));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Paint _arcPaint(Color color, double stroke) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = stroke
  ..strokeCap = StrokeCap.round;

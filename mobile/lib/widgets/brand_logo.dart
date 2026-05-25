import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Zero Hunger mark used on splash and auth screens.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 56,
    this.iconColor = Colors.white,
    this.showWordmark = true,
    this.compactWordmark = false,
    this.light = true,
  });

  final double size;
  final Color iconColor;
  final bool showWordmark;
  final bool compactWordmark;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.18) : green100,
            shape: BoxShape.circle,
            border: Border.all(
              color: light ? Colors.white.withValues(alpha: 0.35) : green200,
              width: 1.5,
            ),
          ),
          child: Icon(Icons.eco_rounded, size: size * 0.52, color: iconColor),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.2),
          Text(
            'Zero Hunger',
            style: TextStyle(
              fontSize: compactWordmark ? 15 : size * 0.38,
              fontWeight: FontWeight.w500,
              color: light ? Colors.white : kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

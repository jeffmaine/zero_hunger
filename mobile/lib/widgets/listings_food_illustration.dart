import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Stylized food box for listings empty states.
class ListingsFoodIllustration extends StatelessWidget {
  const ListingsFoodIllustration({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.85,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.55,
            decoration: BoxDecoration(
              color: const Color(0xFFE8C9A0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC4A574), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.eco_rounded, color: green500.withValues(alpha: 0.35), size: size * 0.28),
                Positioned(
                  top: size * 0.08,
                  child: Icon(Icons.favorite, color: kError.withValues(alpha: 0.85), size: size * 0.12),
                ),
              ],
            ),
          ),
          Positioned(left: size * 0.08, top: size * 0.12, child: _FoodDot(icon: Icons.apple, color: const Color(0xFFE57373))),
          Positioned(right: size * 0.1, top: size * 0.1, child: _FoodDot(icon: Icons.local_drink_outlined, color: const Color(0xFF64B5F6))),
          Positioned(left: size * 0.14, bottom: size * 0.18, child: _FoodDot(icon: Icons.bakery_dining_outlined, color: const Color(0xFFD4A574))),
          Positioned(right: size * 0.12, bottom: size * 0.2, child: _FoodDot(icon: Icons.grass_rounded, color: green500)),
        ],
      ),
    );
  }
}

class _FoodDot extends StatelessWidget {
  const _FoodDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: kSurface,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

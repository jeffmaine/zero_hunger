import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Mockup-style stat tile: icon + "1 Active Listing" + subtitle.
class DonorStatCard extends StatelessWidget {
  const DonorStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.count,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final int count;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: kTextPrimary, height: 1.25),
                      children: [
                        TextSpan(
                          text: '$count ',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

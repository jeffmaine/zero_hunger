import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/claim.dart';
import '../utils/format.dart';

/// Shows active-claim count, cooldown, or no-show pause before requesting food.
class ClaimLimitsBanner extends StatelessWidget {
  const ClaimLimitsBanner({super.key, required this.limits});

  final ClaimLimitsModel limits;

  @override
  Widget build(BuildContext context) {
    if (limits.canClaim && limits.activeClaims == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: green50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: green100),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: green500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Up to ${limits.maxActiveClaims} active claims · donor reviews each request',
                style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    final Color bg;
    final Color border;
    final IconData icon;
    final String text;

    if (limits.isNoShowBlocked) {
      bg = const Color(0xFFFFF0F0);
      border = const Color(0xFFFECACA);
      icon = Icons.block;
      text = limits.message ??
          'Account paused after ${limits.maxNoShows} missed pickups.';
    } else if (limits.cooldownEndsAt != null && !limits.canClaim) {
      bg = const Color(0xFFFFF8E6);
      border = const Color(0xFFFDE68A);
      icon = Icons.hourglass_bottom;
      text = 'Cooldown — try again in ${formatCooldownRemaining(limits.cooldownEndsAt!)}';
    } else if (!limits.canClaim) {
      bg = const Color(0xFFFFF0F0);
      border = const Color(0xFFFECACA);
      icon = Icons.warning_amber_outlined;
      text = limits.message ??
          '${limits.activeClaims} of ${limits.maxActiveClaims} active claims in use';
    } else {
      bg = green50;
      border = green100;
      icon = Icons.info_outline;
      text =
          '${limits.activeClaims} of ${limits.maxActiveClaims} active claims · you can request more';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: limits.canClaim ? green500 : kErrorText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: limits.canClaim ? kTextSecondary : kErrorText,
                height: 1.35,
                fontWeight: limits.canClaim ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

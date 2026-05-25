import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  factory StatusBadge.listing(ListingStatus status) {
    switch (status) {
      case ListingStatus.available:
        return const StatusBadge(label: 'Available', tone: BadgeTone.success);
      case ListingStatus.claimed:
        return const StatusBadge(label: 'Claimed', tone: BadgeTone.warning);
      case ListingStatus.paused:
        return const StatusBadge(label: 'Paused', tone: BadgeTone.info);
      case ListingStatus.completed:
        return const StatusBadge(label: 'Completed', tone: BadgeTone.info);
      case ListingStatus.expired:
        return const StatusBadge(label: 'Expired', tone: BadgeTone.danger);
      case ListingStatus.cancelled:
        return const StatusBadge(label: 'Cancelled', tone: BadgeTone.danger);
    }
  }

  factory StatusBadge.claim(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return const StatusBadge(label: 'Pending', tone: BadgeTone.warning);
      case ClaimStatus.approved:
        return const StatusBadge(label: 'Approved', tone: BadgeTone.success);
      case ClaimStatus.rejected:
        return const StatusBadge(label: 'Rejected', tone: BadgeTone.danger);
      case ClaimStatus.collected:
        return const StatusBadge(label: 'Collected', tone: BadgeTone.info);
    }
  }

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (green100, green500),
      BadgeTone.warning => (const Color(0xFFFEF3E2), const Color(0xFF9A6200)),
      BadgeTone.danger => (kErrorBg, kErrorText),
      BadgeTone.info => (const Color(0xFFE8F0FB), const Color(0xFF1A5FA8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

enum BadgeTone { success, warning, danger, info }

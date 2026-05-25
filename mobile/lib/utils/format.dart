import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/enums.dart';

/// First name with leading capital (e.g. "joseph" → "Joseph").
String formatFirstName(String? fullName, {String fallback = 'there'}) {
  final raw = fullName?.trim().split(RegExp(r'\s+')).firstOrNull;
  if (raw == null || raw.isEmpty) return _capitalizeWord(fallback);
  return _capitalizeWord(raw);
}

/// Title-style casing for food listing names (e.g. "jollof rice" → "Jollof Rice").
String formatListingTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .split(RegExp(r'\s+'))
      .map(_capitalizeWord)
      .join(' ');
}

String _capitalizeWord(String word) {
  if (word.isEmpty) return word;
  if (word.length == 1) return word.toUpperCase();
  return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
}

String formatDistanceKm(double? km) {
  if (km == null) return '';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String formatPickupDeadline(DateTime deadline) {
  final now = DateTime.now();
  final diff = deadline.difference(now);
  if (diff.isNegative) return 'Expired';
  if (diff.inHours >= 24) {
    return DateFormat('EEE h:mm a').format(deadline.toLocal());
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours}h ${diff.inMinutes % 60}m left';
  }
  return '${diff.inMinutes}m left';
}

bool isUrgentDeadline(DateTime deadline, {Duration threshold = const Duration(hours: 4)}) {
  return deadline.difference(DateTime.now()) <= threshold &&
      deadline.isAfter(DateTime.now());
}

bool isCriticalDeadline(DateTime deadline) {
  return deadline.difference(DateTime.now()) <= const Duration(hours: 1) &&
      deadline.isAfter(DateTime.now());
}

/// e.g. "10 portions" → "Feeds 10 portions"; keeps strings that already mention feed.
String formatFeedsLabel(String quantity) {
  final q = quantity.trim();
  if (q.isEmpty) return 'Feeds —';
  if (RegExp(r'feed', caseSensitive: false).hasMatch(q)) return q;
  return 'Feeds $q';
}

String formatCooldownRemaining(DateTime endsAtUtc) {
  final remaining = endsAtUtc.difference(DateTime.now().toUtc());
  if (!remaining.isNegative && remaining.inMinutes < 1) return 'under 1 min';
  if (remaining.isNegative) return 'soon';
  final h = remaining.inHours;
  final m = remaining.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${remaining.inMinutes} min';
}

String formatRelativeTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dt.toLocal());
}

Color deadlineColor(DateTime deadline) {
  if (isCriticalDeadline(deadline)) return kErrorText;
  if (isUrgentDeadline(deadline, threshold: const Duration(hours: 2))) return kAccent;
  return kTextSecondary;
}

/// Pickup deadline display — live countdown only while listing is still in play.
String formatListingDeadline({
  required ListingStatus status,
  required DateTime deadline,
}) {
  switch (status) {
    case ListingStatus.completed:
      return 'Pickup completed';
    case ListingStatus.expired:
      return 'Expired';
    case ListingStatus.cancelled:
      return 'Cancelled';
    case ListingStatus.paused:
      return 'Paused';
    case ListingStatus.available:
    case ListingStatus.claimed:
      return formatPickupDeadline(deadline);
  }
}

Color listingDeadlineColor({
  required ListingStatus status,
  required DateTime deadline,
}) {
  switch (status) {
    case ListingStatus.completed:
      return green500;
    case ListingStatus.expired:
    case ListingStatus.cancelled:
      return kTextDisabled;
    case ListingStatus.paused:
      return kTextSecondary;
    case ListingStatus.available:
    case ListingStatus.claimed:
      return deadlineColor(deadline);
  }
}

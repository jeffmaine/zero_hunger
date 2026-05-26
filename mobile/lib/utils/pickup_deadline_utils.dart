import 'package:intl/intl.dart';

/// Minimum lead time before pickup window ends.
const Duration kMinPickupLeadTime = Duration(minutes: 30);

/// Latest deadline donors can set from now.
const Duration kMaxPickupHorizon = Duration(days: 7);

DateTime roundDeadlineToQuarterHour(DateTime dt) {
  final local = dt.toLocal();
  final remainder = local.minute % 15;
  final addMinutes = remainder == 0 ? 0 : 15 - remainder;
  final rounded = local.add(Duration(minutes: addMinutes));
  return DateTime(
    rounded.year,
    rounded.month,
    rounded.day,
    rounded.hour,
    rounded.minute,
  );
}

DateTime deadlineFromNow(Duration offset) {
  return roundDeadlineToQuarterHour(DateTime.now().add(offset));
}

DateTime tonightDeadline() {
  final now = DateTime.now();
  var candidate = DateTime(now.year, now.month, now.day, 21, 0);
  if (!candidate.isAfter(now.add(kMinPickupLeadTime))) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

DateTime tomorrowAt(int hour, int minute) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
}

/// Human label on the post-food form.
String formatPickupDeadlineChoice(DateTime deadline) {
  final local = deadline.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = DateFormat('h:mm a').format(local);

  if (day == today) return 'Today · $time';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow · $time';
  return '${DateFormat('EEE, MMM d').format(local)} · $time';
}

/// Subtitle under the main deadline line.
String formatPickupDeadlineHint(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff < kMinPickupLeadTime) {
    return 'Choose a time at least 30 minutes from now';
  }
  if (diff.inHours < 1) {
    return 'Receivers have ${diff.inMinutes} minutes to collect — window ends soon';
  }
  if (diff.inHours < 24) {
    return 'Receivers can collect within the next ${diff.inHours}h ${diff.inMinutes % 60}m';
  }
  final days = diff.inDays;
  if (days == 1) return 'About 1 day for receivers to arrange pickup';
  return 'About $days days for receivers to arrange pickup';
}

String? validatePickupDeadline(DateTime deadline) {
  final now = DateTime.now();
  if (!deadline.isAfter(now.add(kMinPickupLeadTime))) {
    return 'Pickup must end at least 30 minutes from now';
  }
  if (deadline.isAfter(now.add(kMaxPickupHorizon))) {
    return 'Pickup cannot be more than 7 days away';
  }
  return null;
}

class PickupDeadlinePreset {
  const PickupDeadlinePreset(this.label, this.resolve);

  final String label;
  final DateTime Function() resolve;
}

final List<PickupDeadlinePreset> pickupDeadlinePresets = [
  PickupDeadlinePreset('2 hours', () => deadlineFromNow(const Duration(hours: 2))),
  PickupDeadlinePreset('4 hours', () => deadlineFromNow(const Duration(hours: 4))),
  PickupDeadlinePreset('6 hours', () => deadlineFromNow(const Duration(hours: 6))),
  PickupDeadlinePreset('Tonight 9pm', tonightDeadline),
  PickupDeadlinePreset('Tomorrow noon', () => tomorrowAt(12, 0)),
  PickupDeadlinePreset('Tomorrow 6pm', () => tomorrowAt(18, 0)),
];

bool deadlinesMatchPreset(DateTime deadline, PickupDeadlinePreset preset) {
  final target = preset.resolve();
  return deadline.difference(target).inMinutes.abs() < 2;
}

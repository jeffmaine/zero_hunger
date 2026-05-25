import 'format.dart';

/// Time-of-day greeting for home screens.
String timeOfDayGreeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String greetingWithName(String? fullName, {String fallback = 'there'}) {
  return '${timeOfDayGreeting()}, ${formatFirstName(fullName, fallback: fallback)}';
}

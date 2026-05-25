/// Safe parsing for API JSON (UUIDs may arrive as String or nested values).
String parseUuid(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? parseUuidOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

DateTime parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.parse(value.toString());
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

/// Parses a DateTime from various serialized formats.
///
/// Tries ISO-8601 string first, then epoch milliseconds integer.
/// Falls back to [fallback] if parsing fails or value is null.
DateTime? parseDateTime(dynamic value, {DateTime? fallback}) {
  if (value == null) return fallback;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return fallback;
    }
  }
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return fallback;
    }
  }
  if (value is num) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}

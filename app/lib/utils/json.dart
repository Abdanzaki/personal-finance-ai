/// Tolerant JSON number parsing.
///
/// The backend serializes Decimal money values as strings (e.g. "0.0"),
/// while some fields arrive as real JSON numbers. These helpers accept
/// either shape so a single backend change can't crash the UI.
double parseDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

int parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

/// Nullable variant: returns null when the value itself is null.
double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  return parseDouble(value);
}

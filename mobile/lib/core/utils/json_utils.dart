/// Helpers for Spring/Jackson JSON quirks. Use them in `@JsonKey(fromJson: ...)`.
library;

/// Parses a Java `LocalDate` / `LocalDateTime`.
///
/// Jackson sends ISO strings (`"2026-09-25"`, `"2026-09-25T14:03:00"`), but some
/// configurations send arrays (`[2026, 9, 25, 14, 3, 0]`). Both are handled.
DateTime? parseApiDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is List && value.length >= 3) {
    final parts = value.map((e) => (e as num).toInt()).toList();
    return DateTime(
      parts[0],
      parts[1],
      parts[2],
      parts.length > 3 ? parts[3] : 0,
      parts.length > 4 ? parts[4] : 0,
      parts.length > 5 ? parts[5] : 0,
    );
  }
  return null;
}

/// Formats a date the way Spring expects a `LocalDate` (`yyyy-MM-dd`).
String? formatApiDate(DateTime? date) =>
    date?.toIso8601String().split('T').first;

/// Common time zones and their summer-time rules, to show anyone's local time
/// without an extra package. Unknown zones fall back to the offset saved on the profile.
library;

/// Summer-time rule of a zone.
enum DstRule { none, eu, us, egypt, au }

class TimeZoneInfo {
  const TimeZoneInfo(this.name, this.city, this.standardOffsetMinutes, [this._dst = DstRule.none]);

  /// IANA name, e.g. "Africa/Tunis" (what the backend stores).
  final String name;
  final String city;
  final int standardOffsetMinutes;
  final DstRule _dst;

  Duration offsetAt(DateTime utc) {
    final standard = Duration(minutes: standardOffsetMinutes);
    return _inSummerTime(utc.add(standard), _dst) ? standard + const Duration(hours: 1) : standard;
  }
}

abstract final class TimeZones {
  static const all = [
    TimeZoneInfo('Africa/Tunis', 'Tunis', 60),
    TimeZoneInfo('Africa/Algiers', 'Algiers', 60),
    TimeZoneInfo('Africa/Casablanca', 'Casablanca', 60),
    TimeZoneInfo('Africa/Cairo', 'Cairo', 120, DstRule.egypt),
    TimeZoneInfo('Africa/Lagos', 'Lagos', 60),
    TimeZoneInfo('Africa/Johannesburg', 'Johannesburg', 120),
    TimeZoneInfo('Africa/Nairobi', 'Nairobi', 180),
    TimeZoneInfo('Europe/London', 'London', 0, DstRule.eu),
    TimeZoneInfo('Europe/Paris', 'Paris', 60, DstRule.eu),
    TimeZoneInfo('Europe/Berlin', 'Berlin', 60, DstRule.eu),
    TimeZoneInfo('Europe/Madrid', 'Madrid', 60, DstRule.eu),
    TimeZoneInfo('Europe/Rome', 'Rome', 60, DstRule.eu),
    TimeZoneInfo('Europe/Athens', 'Athens', 120, DstRule.eu),
    TimeZoneInfo('Europe/Istanbul', 'Istanbul', 180),
    TimeZoneInfo('Europe/Moscow', 'Moscow', 180),
    TimeZoneInfo('Asia/Riyadh', 'Riyadh', 180),
    TimeZoneInfo('Asia/Dubai', 'Dubai', 240),
    TimeZoneInfo('Asia/Karachi', 'Karachi', 300),
    TimeZoneInfo('Asia/Kolkata', 'India', 330),
    TimeZoneInfo('Asia/Dhaka', 'Dhaka', 360),
    TimeZoneInfo('Asia/Bangkok', 'Bangkok', 420),
    TimeZoneInfo('Asia/Shanghai', 'Beijing', 480),
    TimeZoneInfo('Asia/Singapore', 'Singapore', 480),
    TimeZoneInfo('Asia/Tokyo', 'Tokyo', 540),
    TimeZoneInfo('Australia/Sydney', 'Sydney', 600, DstRule.au),
    TimeZoneInfo('America/Sao_Paulo', 'São Paulo', -180),
    TimeZoneInfo('America/New_York', 'New York', -300, DstRule.us),
    TimeZoneInfo('America/Toronto', 'Toronto', -300, DstRule.us),
    TimeZoneInfo('America/Chicago', 'Chicago', -360, DstRule.us),
    TimeZoneInfo('America/Mexico_City', 'Mexico City', -360),
    TimeZoneInfo('America/Denver', 'Denver', -420, DstRule.us),
    TimeZoneInfo('America/Los_Angeles', 'Los Angeles', -480, DstRule.us),
    TimeZoneInfo('UTC', 'UTC', 0),
  ];

  static TimeZoneInfo? byName(String name) => all.where((z) => z.name == name).firstOrNull;

  /// Current offset of [name], or null if the zone isn't in the list.
  static Duration? offsetOf(String name, DateTime utc) => byName(name)?.offsetAt(utc);

  /// The zone matching the phone's current offset (Tunis first for +1, the team's home).
  static TimeZoneInfo guessForDevice([DateTime? now]) {
    final local = now ?? DateTime.now();
    final offset = local.timeZoneOffset;
    final utc = local.toUtc();
    return all.where((z) => z.offsetAt(utc) == offset).firstOrNull ?? all.last;
  }

  /// "UTC+1", "UTC−5", "UTC+5:30".
  static String formatOffset(Duration offset) {
    final minutes = offset.inMinutes;
    if (minutes == 0) return 'UTC';
    final sign = minutes > 0 ? '+' : '−';
    final h = minutes.abs() ~/ 60;
    final m = minutes.abs() % 60;
    return 'UTC$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
  }
}

/// [localStandard] is the wall-clock time without summer time.
bool _inSummerTime(DateTime localStandard, DstRule rule) {
  final y = localStandard.year;
  DateTime at(int month, int day, [int hour = 0]) => DateTime.utc(y, month, day, hour);
  final t = DateTime.utc(y, localStandard.month, localStandard.day, localStandard.hour, localStandard.minute);
  switch (rule) {
    case DstRule.none:
      return false;
    case DstRule.eu: // last Sunday of March → last Sunday of October (01:00 UTC ≈ 02:00 local)
      return !t.isBefore(at(3, _lastWeekday(y, 3, DateTime.sunday), 2)) &&
          t.isBefore(at(10, _lastWeekday(y, 10, DateTime.sunday), 2));
    case DstRule.us: // second Sunday of March → first Sunday of November, 02:00 local
      return !t.isBefore(at(3, _nthWeekday(y, 3, DateTime.sunday, 2), 2)) &&
          t.isBefore(at(11, _nthWeekday(y, 11, DateTime.sunday, 1), 1));
    case DstRule.egypt: // last Friday of April → last Thursday of October
      return !t.isBefore(at(4, _lastWeekday(y, 4, DateTime.friday))) &&
          t.isBefore(at(10, _lastWeekday(y, 10, DateTime.thursday), 23));
    case DstRule.au: // southern hemisphere: not between first Sunday of April and first Sunday of October
      return t.isBefore(at(4, _nthWeekday(y, 4, DateTime.sunday, 1), 2)) ||
          !t.isBefore(at(10, _nthWeekday(y, 10, DateTime.sunday, 1), 2));
  }
}

int _lastWeekday(int year, int month, int weekday) {
  var day = DateTime.utc(year, month + 1, 0); // last day of the month
  while (day.weekday != weekday) {
    day = day.subtract(const Duration(days: 1));
  }
  return day.day;
}

int _nthWeekday(int year, int month, int weekday, int n) {
  var day = DateTime.utc(year, month, 1);
  while (day.weekday != weekday) {
    day = day.add(const Duration(days: 1));
  }
  return day.day + 7 * (n - 1);
}

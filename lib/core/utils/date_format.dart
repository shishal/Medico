/// Small date formatters. `intl` is not in the locked dependency set and we
/// only ever render English, so a handful of lookup tables is cheaper than a
/// package.
abstract final class DateFormats {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // DateTime.weekday is 1 (Monday) … 7 (Sunday), so index 0 is unused.
  static const _weekdays = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// `20 Sep 2026`. Always pass a local `DateTime`.
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// `Sat 29` for a `yyyy-MM-dd` string, falling back to the raw input when
  /// the server sends something unexpected.
  static String weekdayAndDay(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return '${_weekdays[parsed.weekday]} ${parsed.day}';
  }

  /// How a plan expiry should read to a student: a countdown while it is close,
  /// then a plain date. [now] is injectable so tests do not depend on the clock.
  static String planExpiry(DateTime expiresAt, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final local = expiresAt.toLocal();
    if (local.isBefore(today)) return 'expired ${dayMonthYear(local)}';

    final days = local.difference(today).inDays;
    return switch (days) {
      0 => 'expires today',
      1 => 'expires tomorrow',
      < 30 => 'expires in $days days',
      _ => 'until ${dayMonthYear(local)}',
    };
  }
}

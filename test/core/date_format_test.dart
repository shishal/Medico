import 'package:flutter_test/flutter_test.dart';
import 'package:medico/core/utils/date_format.dart';

void main() {
  test('dayMonthYear renders a readable date', () {
    expect(DateFormats.dayMonthYear(DateTime(2026, 9, 20)), '20 Sep 2026');
    expect(DateFormats.dayMonthYear(DateTime(2026, 1, 5)), '5 Jan 2026');
  });

  test('weekdayAndDay names the day instead of showing 08-29', () {
    // 2026-08-29 is a Saturday.
    expect(DateFormats.weekdayAndDay('2026-08-29'), 'Sat 29');
  });

  test('weekdayAndDay falls back to the raw string when unparseable', () {
    expect(DateFormats.weekdayAndDay('not-a-date'), 'not-a-date');
  });

  group('planExpiry', () {
    final now = DateTime(2026, 9, 16, 10);

    test('counts down while the expiry is close', () {
      expect(
        DateFormats.planExpiry(DateTime(2026, 9, 16, 20), now: now),
        'expires today',
      );
      expect(
        DateFormats.planExpiry(DateTime(2026, 9, 17, 20), now: now),
        'expires tomorrow',
      );
      expect(
        DateFormats.planExpiry(DateTime(2026, 9, 21, 20), now: now),
        'expires in 5 days',
      );
    });

    test('switches to a plain date once it is far off', () {
      expect(
        DateFormats.planExpiry(DateTime(2027, 3, 14, 20), now: now),
        'until 14 Mar 2027',
      );
    });

    test('says so when the plan has already lapsed', () {
      expect(
        DateFormats.planExpiry(DateTime(2026, 8, 1), now: now),
        'expired 1 Aug 2026',
      );
    });
  });
}

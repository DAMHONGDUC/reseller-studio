import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/utils/date_time_utils.dart';

/// All date arithmetic in the app goes through one class (owner's rule), so
/// these are the tests for the parts that are easy to get subtly wrong.
void main() {
  group('daysBetween counts midnights, not hours', () {
    test('23:00 yesterday to 08:00 today is one day, not zero', () {
      // `difference().inDays` reports 0 here — nine hours — which is not what
      // a seller means by "how many days has this sat".
      expect(
        DateTimeUtils.daysBetween(
          DateTime(2026, 8, 11, 23),
          DateTime(2026, 8, 12, 8),
        ),
        1,
      );
    });

    test('a deadline already past comes back negative', () {
      expect(
        DateTimeUtils.daysBetween(
          DateTime(2026, 8, 12),
          DateTime(2026, 8, 9),
        ),
        -3,
      );
    });
  });

  group('monthsBefore clamps to a shorter month', () {
    test('31 March minus one month is 28 February, not 3 March', () {
      expect(
        DateTimeUtils.monthsBefore(DateTime(2026, 3, 31), 1),
        DateTime(2026, 2, 28),
      );
    });

    test('it steps back across a year boundary', () {
      expect(
        DateTimeUtils.monthsBefore(DateTime(2026, 1, 15), 2),
        DateTime(2025, 11, 15),
      );
    });

    test('a leap February keeps its 29th', () {
      expect(
        DateTimeUtils.monthsBefore(DateTime(2024, 3, 31), 1),
        DateTime(2024, 2, 29),
      );
    });
  });

  group('isWithin is half-open', () {
    test('the start is inside the range and the end is not', () {
      final DateTime from = DateTime(2026, 8, 1);
      final DateTime to = DateTime(2026, 9, 1);

      expect(DateTimeUtils.isWithin(from, from: from, to: to), isTrue);
      expect(DateTimeUtils.isWithin(to, from: from, to: to), isFalse);
    });

    test('an open end accepts anything after the start', () {
      expect(
        DateTimeUtils.isWithin(DateTime(2030), from: DateTime(2026, 8, 1)),
        isTrue,
      );
    });
  });

  group('compactAge changes unit where the smaller one stops reading', () {
    test('under a day', () {
      expect(DateTimeUtils.compactAge(const Duration(hours: 5)), '<1d');
    });

    test('days, then weeks, then months, then years', () {
      expect(DateTimeUtils.compactAge(const Duration(days: 3)), '3d');
      expect(DateTimeUtils.compactAge(const Duration(days: 21)), '3w');
      expect(DateTimeUtils.compactAge(const Duration(days: 90)), '3mo');
      expect(DateTimeUtils.compactAge(const Duration(days: 800)), '2y');
    });
  });

  test('isoDate is not localized, so filenames and CSV cells sort', () {
    expect(DateTimeUtils.isoDate(DateTime(2026, 8, 5)), '2026-08-05');
  });
}

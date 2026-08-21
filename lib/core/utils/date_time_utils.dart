import 'package:intl/intl.dart';

/// **All date and time arithmetic in the app lives here** — owner's rule.
///
/// Clock formatting, month arithmetic and a chart's time axis are one
/// subject, and two date-shaped utility classes is how the same call site
/// ends up computing midnight two different ways.
///
/// Every formatter takes a [locale] rather than defaulting: a Vietnamese
/// seller and an American one disagree about what a date looks like, and a
/// silent default makes that disagreement invisible until someone reports it.
final class DateTimeUtils {
  /// `12 Aug` — a row in a list, where the year is noise.
  static String shortDate(DateTime value, {required String locale}) =>
      DateFormat.MMMd(locale).format(value);

  /// `12 Aug 2026` — a detail screen, a receipt, anything filed by year.
  static String mediumDate(DateTime value, {required String locale}) =>
      DateFormat.yMMMd(locale).format(value);

  /// `Aug 2026` — a monthly report's heading.
  static String monthLabel(DateTime value, {required String locale}) =>
      DateFormat.yMMM(locale).format(value);

  /// `12 Aug, 14:30` — an activity entry, where the time is the point.
  static String dateTime(DateTime value, {required String locale}) =>
      '${DateFormat.MMMd(locale).format(value)}, '
      '${DateFormat.Hm(locale).format(value)}';

  /// `2026-08-12` — a filename or a CSV cell.
  ///
  /// **Deliberately not localized.** A file sorted by name has to sort by
  /// date, and a spreadsheet has to parse it — both want ISO, whoever is
  /// looking at it.
  static String isoDate(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);

  /// Whole days between two instants, ignoring the time of day.
  ///
  /// Midnight-to-midnight rather than `difference().inDays`, which reports
  /// zero for 23:00 yesterday to 08:00 today — technically nine hours, and
  /// not what a seller means by "how many days has this sat".
  static int daysBetween(DateTime from, DateTime to) =>
      startOfDay(to).difference(startOfDay(from)).inDays;

  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime startOfMonth(DateTime value) =>
      DateTime(value.year, value.month);

  /// The same day-of-month [months] back, clamped to the end of a shorter
  /// month — 31 March minus one month is 28 February, not 3 March.
  static DateTime monthsBefore(DateTime value, int months) {
    final int totalMonths = value.year * 12 + (value.month - 1) - months;
    final int year = totalMonths ~/ 12;
    final int month = totalMonths % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day;

    return DateTime(year, month, value.day.clamp(1, lastDay));
  }

  /// The same day-of-month [months] forward, clamped the same way — 31
  /// January plus one month is 28 February.
  static DateTime monthsAfter(DateTime value, int months) =>
      monthsBefore(value, -months);

  /// Whether [value] falls inside the half-open range `[from, to)`.
  static bool isWithin(DateTime value, {DateTime? from, DateTime? to}) {
    if (from != null && value.isBefore(from)) return false;
    if (to != null && !value.isBefore(to)) return false;

    return true;
  }

  /// `3d`, `5w`, `2mo` — how long something has been sitting.
  ///
  /// Short on purpose: it renders inside a chip on an inventory row, where
  /// "3 days ago" would push the price off the end. The unit changes at the
  /// point where the smaller one stops being readable at a glance.
  static String compactAge(Duration age) {
    final int days = age.inDays;

    if (days < 1) return '<1d';
    if (days < 14) return '${days}d';
    if (days < 60) return '${days ~/ 7}w';
    if (days < 365) return '${days ~/ 30}mo';

    return '${days ~/ 365}y';
  }
}

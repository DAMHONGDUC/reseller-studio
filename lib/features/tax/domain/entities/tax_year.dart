import '../enums/tax_jurisdiction.dart';

/// One filing period, with the two dates that bound it (plan §20).
///
/// **A value type, not a utils class.** `DateTimeUtils` owns date arithmetic
/// (`CLAUDE.md`), and this owns the one fact that arithmetic cannot know: a
/// tax year is not a calendar year everywhere. The US files January to
/// December; the UK files 6 April to 5 April, so its 2026/27 year opens in
/// April 2026 and closes in April 2027.
///
/// [startingYear] is the calendar year the period **opens** in, which is the
/// half both jurisdictions agree on.
class TaxYear {
  const TaxYear({required this.jurisdiction, required this.startingYear});

  /// The year [when] falls in.
  ///
  /// A UK date in February belongs to the year that opened the previous
  /// April — the case a naive `date.year` gets wrong for a quarter of the
  /// calendar, and the reason this is not written at a call site.
  factory TaxYear.containing(DateTime when, TaxJurisdiction jurisdiction) {
    final DateTime opensThisYear = DateTime(
      when.year,
      jurisdiction.yearStartMonth,
      jurisdiction.yearStartDay,
    );

    return TaxYear(
      jurisdiction: jurisdiction,
      startingYear: when.isBefore(opensThisYear) ? when.year - 1 : when.year,
    );
  }

  final TaxJurisdiction jurisdiction;
  final int startingYear;

  DateTime get start => DateTime(
    startingYear,
    jurisdiction.yearStartMonth,
    jurisdiction.yearStartDay,
  );

  /// The first instant of the **next** year — an exclusive upper bound.
  ///
  /// Exclusive on purpose: an inclusive end date has to be "the last day at
  /// 23:59:59.999", and every comparison written against that eventually
  /// drops a sale timestamped in the last second of the year.
  DateTime get endExclusive =>
      TaxYear(jurisdiction: jurisdiction, startingYear: startingYear + 1).start;

  bool contains(DateTime when) =>
      !when.isBefore(start) && when.isBefore(endExclusive);

  /// `2026` in the US, `2026/27` in the UK — what the seller's own tax
  /// authority calls it.
  String get label {
    if (!jurisdiction.yearSpansTwoCalendarYears) return '$startingYear';

    final String shortEnd = ((startingYear + 1) % 100).toString().padLeft(
      2,
      '0',
    );

    return '$startingYear/$shortEnd';
  }

  TaxYear get previous =>
      TaxYear(jurisdiction: jurisdiction, startingYear: startingYear - 1);

  @override
  bool operator ==(Object other) =>
      other is TaxYear &&
      other.jurisdiction == jurisdiction &&
      other.startingYear == startingYear;

  @override
  int get hashCode => Object.hash(jurisdiction, startingYear);
}

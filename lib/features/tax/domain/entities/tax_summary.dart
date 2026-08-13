import '../../../../core/money/money.dart';
import 'tax_year.dart';

/// One line of the year-end summary: what a form line came to.
class TaxLineTotal {
  const TaxLineTotal({required this.line, required this.amount});

  final String line;

  /// Null when nothing was recorded against this line — rendered `—`, never
  /// `0` (hard rule 5). A zero here would read as "you spent nothing on
  /// advertising", when the truth is usually "you have not entered it yet".
  final Money? amount;
}

/// What the seller made and spent in one filing period (plan §20).
///
/// **Derived at read time, like every other figure in this app** (hard rule
/// 3). Nothing here is stored: a fee corrected in March changes last year's
/// summary the next time it is opened, which is the behaviour a return needs.
///
/// **This is a summary of the seller's own records, not a tax computation.**
/// It does not apply allowances, thresholds, rates or reliefs, and it is not
/// advice. The screen says so; this class says so too, because the next
/// person to add a "tax owed" field should read this first.
class TaxSummary {
  const TaxSummary({
    required this.year,
    required this.revenue,
    required this.costOfGoods,
    required this.lines,
    required this.mileageDistance,
    required this.mileageDeduction,
    required this.currency,
  });

  factory TaxSummary.empty(TaxYear year, String currency) => TaxSummary(
    year: year,
    revenue: null,
    costOfGoods: null,
    lines: const <TaxLineTotal>[],
    mileageDistance: 0,
    mileageDeduction: null,
    currency: currency,
  );

  final TaxYear year;
  final Money? revenue;
  final Money? costOfGoods;

  /// One entry per line of the jurisdiction's form, in the form's own order —
  /// including the lines that came to nothing, so a seller reading down their
  /// return can tick each one off.
  final List<TaxLineTotal> lines;

  final double mileageDistance;

  /// Null when no published rate covers the year. Distinct from zero: zero
  /// means no miles, null means the app does not know the rate.
  final Money? mileageDeduction;

  final String currency;

  /// Everything deductible, mileage included.
  Money? get totalDeductions {
    final List<Money?> parts = <Money?>[
      for (final TaxLineTotal line in lines) line.amount,
      mileageDeduction,
    ];

    return parts.totalOfKnown();
  }

  /// Revenue less cost of goods less deductions.
  ///
  /// Null when revenue is unknown — a net figure computed from a missing
  /// revenue is a number that looks authoritative and is not.
  Money? get netBeforeTax {
    final Money? sales = revenue;

    if (sales == null) return null;

    final Money zero = Money.zero(currency);

    return sales - (costOfGoods ?? zero) - (totalDeductions ?? zero);
  }
}

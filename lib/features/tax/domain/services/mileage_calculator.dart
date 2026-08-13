import '../../../../core/money/money.dart';
import '../entities/mileage_rate.dart';
import '../enums/tax_jurisdiction.dart';

/// Turns miles driven into a deduction (plan §20).
///
/// **Banded, and the bands are cumulative over the whole tax year** — not per
/// journey. HMRC's 10,000-mile threshold applies to the year's total, so
/// summing each trip at its own first-band rate would over-deduct for anyone
/// who drives a lot. The US has one band and the same code path serves it.
///
/// Pure, and it takes the distance rather than reading it: the boundaries are
/// the only interesting part, and a calculator that fetched its own rows
/// could not be tested at them.
final class MileageCalculator {
  /// The deduction for [distance] driven in a year whose rate is [rate].
  ///
  /// Null when no rate is published for that date — a missing rate renders as
  /// `—`, never as a zero deduction (hard rule 5). Telling a seller their
  /// mileage is worth nothing is worse than telling them it is unknown.
  static Money? deduction({
    required double distance,
    required MileageRate? rate,
    required String currency,
  }) {
    if (rate == null) return null;
    if (distance <= 0) return Money.zero(currency);

    double remaining = distance;
    double consumed = 0;
    int totalMinor = 0;

    for (final MileageBand band in rate.bands) {
      if (remaining <= 0) break;

      final double? ceiling = band.upToDistance;
      final double width = ceiling == null
          ? remaining
          : (ceiling - consumed).clamp(0, remaining);

      // `round`, not `floor`: truncating every band understates the year by a
      // little, always in the tax authority's favour and never the seller's.
      totalMinor += (width * band.rateMinor).round();
      consumed += width;
      remaining -= width;
    }

    return Money(totalMinor, currency);
  }

  /// The rate that applies to a journey, by its own date.
  ///
  /// **The journey's date, never today.** A return filed in March deducts
  /// last year's miles at last year's rate, and reading the wall clock here
  /// would quietly re-rate a whole year the moment the IRS publishes a new
  /// figure.
  static MileageRate? rateFor(TaxJurisdiction jurisdiction, DateTime when) =>
      MileageRateConstant.inForce(jurisdiction, when);
}

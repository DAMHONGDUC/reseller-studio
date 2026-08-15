import '../../../../core/money/money.dart';
import '../entities/mileage_journey.dart';
import '../entities/mileage_rate.dart';
import '../enums/tax_jurisdiction.dart';

/// Turns miles driven into a deduction (plan §20).
///
/// Two things decide what a mile is worth, and they are independent:
///
/// - **the band**, which is cumulative over the whole tax year** — HMRC's
///   10,000-mile threshold applies to the year's total, so summing each trip
///   at its own first-band rate would over-deduct for anyone who drives a lot;
/// - **the rate**, which is the one in force on the journey's own date. The
///   IRS raised its 2026 figure on 1 July, so a year cannot be rated by a
///   single number without understating half of it.
///
/// Pure, and it takes the journeys rather than reading them: the boundaries
/// are the only interesting part, and a calculator that fetched its own rows
/// could not be tested at them.
final class MileageCalculator {
  /// The year's deduction, each journey rated by its own date and banded by
  /// how far the year had already run.
  ///
  /// Null when nothing is published for a journey's date — a missing rate
  /// renders as `—`, never as a zero deduction (hard rule 5). Telling a
  /// seller their mileage is worth nothing is worse than telling them it is
  /// unknown, so one unrated journey makes the whole figure unknown rather
  /// than quietly contributing nothing.
  static Money? forJourneys({
    required List<MileageJourney> journeys,
    required TaxJurisdiction jurisdiction,
    required String currency,
  }) {
    final List<MileageJourney> ordered = List<MileageJourney>.of(journeys)
      ..sort((MileageJourney a, MileageJourney b) => a.date.compareTo(b.date));

    double consumed = 0;
    double hundredths = 0;

    for (final MileageJourney journey in ordered) {
      if (journey.distance <= 0) continue;

      final MileageRate? rate = rateFor(jurisdiction, journey.date);

      if (rate == null) return null;

      hundredths += _hundredthsForSegment(
        from: consumed,
        distance: journey.distance,
        bands: rate.bands,
      );
      consumed += journey.distance;
    }

    return Money(_toMinor(hundredths), currency);
  }

  /// The deduction for [distance] driven under one [rate], from a standing
  /// start.
  ///
  /// The single-rate case, for a caller that already knows every journey fell
  /// under the same table. [forJourneys] is what a tax year should use.
  static Money? deduction({
    required double distance,
    required MileageRate? rate,
    required String currency,
  }) {
    if (rate == null) return null;
    if (distance <= 0) return Money.zero(currency);

    return Money(
      _toMinor(
        _hundredthsForSegment(from: 0, distance: distance, bands: rate.bands),
      ),
      currency,
    );
  }

  /// What the stretch of road from [from] to `from + distance` is worth, in
  /// hundredths of a minor unit.
  ///
  /// [from] is how far the year has already run, which is what places the
  /// segment against the bands. Bands are cumulative ceilings from zero, not
  /// widths.
  static double _hundredthsForSegment({
    required double from,
    required double distance,
    required List<MileageBand> bands,
  }) {
    double remaining = distance;
    double consumed = from;
    double total = 0;

    for (final MileageBand band in bands) {
      if (remaining <= 0) break;

      final double? ceiling = band.upToDistance;
      final double width = ceiling == null
          ? remaining
          : (ceiling - consumed).clamp(0, remaining);

      total += width * band.rateMinorHundredths;
      consumed += width;
      remaining -= width;
    }

    return total;
  }

  /// Rounded once, at the end.
  ///
  /// `round`, not `floor`: truncating understates the year a little, always
  /// in the tax authority's favour and never the seller's. Rounding here
  /// rather than per band keeps a year of short trips from losing half a cent
  /// apiece.
  static int _toMinor(double hundredths) =>
      (hundredths / MileageBand.rateScale).round();

  /// The rate that applies to a journey, by its own date.
  ///
  /// **The journey's date, never today.** Reading the wall clock here would
  /// quietly re-rate a whole year the moment the IRS publishes a new figure.
  static MileageRate? rateFor(TaxJurisdiction jurisdiction, DateTime when) =>
      MileageRateConstant.inForce(jurisdiction, when);
}

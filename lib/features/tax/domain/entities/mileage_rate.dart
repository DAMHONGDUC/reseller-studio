import '../enums/tax_jurisdiction.dart';

/// One band of a mileage rate: a rate that applies up to a distance.
///
/// The UK pays 45p for the first 10,000 business miles and 25p after that, so
/// a single rate cannot express it. The US has one band with no ceiling, and
/// modelling that as a one-element list rather than a special case is what
/// keeps the calculator free of `if (isUk)`.
class MileageBand {
  const MileageBand({required this.upToDistance, required this.rateMinor});

  /// The distance this band runs to, or null for "everything above the last
  /// band". Cumulative from zero, not a width.
  final double? upToDistance;

  /// Minor units per [MileageUnit] — cents per mile, pence per mile.
  ///
  /// **Integer minor units, like every other amount in this app** (hard rule
  /// 4). 67 cents is representable; 0.67 dollars is not, and a year of
  /// mileage summed in doubles drifts visibly.
  final int rateMinor;
}

/// What one jurisdiction allows per mile, from a given date.
///
/// **Dated, because these change every year** and are set by the IRS and
/// HMRC, not by this app. A rate typed into a widget is a wrong deduction the
/// following April — see `docs/rules/DECISIONS.md`.
class MileageRate {
  const MileageRate({
    required this.jurisdiction,
    required this.effectiveFrom,
    required this.bands,
  });

  final TaxJurisdiction jurisdiction;

  /// The first day this rate applies. Compared against the *journey's* date,
  /// never against today: a return filed in March deducts last year's miles
  /// at last year's rate.
  final DateTime effectiveFrom;

  final List<MileageBand> bands;
}

/// The published rates, newest last.
///
/// **Checked-in data, and the one place a rate is written.** It is here
/// rather than in Firestore because a wrong rate is a wrong tax return: this
/// list is reviewable in a diff, and a remote value that changed under the
/// app would not be.
///
/// **These must be verified against the IRS and HMRC before release.** They
/// are the published figures at the time of writing; nobody should file from
/// them without checking, and `RELEASE_ACTIONS.md` carries that as an item.
final class MileageRateConstant {
  static final List<MileageRate> published = <MileageRate>[
    // IRS standard mileage rate, business use. One band, no ceiling.
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2024),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinor: 67),
      ],
    ),
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2025),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinor: 70),
      ],
    ),
    // HMRC approved mileage allowance payments, cars and vans. Two bands, and
    // the 10,000-mile threshold is per tax year rather than per journey.
    MileageRate(
      jurisdiction: TaxJurisdiction.uk,
      effectiveFrom: DateTime(2011, DateTime.april, 6),
      bands: const <MileageBand>[
        MileageBand(upToDistance: 10000, rateMinor: 45),
        MileageBand(upToDistance: null, rateMinor: 25),
      ],
    ),
  ];

  /// The rate in force for [when], or null when the tables do not reach back
  /// that far.
  ///
  /// Null rather than the oldest rate: deducting a 2026 journey at a 2011
  /// rate is a wrong number presented as a right one, and hard rule 5's
  /// reasoning applies — missing is not zero, and it is not a guess either.
  static MileageRate? inForce(TaxJurisdiction jurisdiction, DateTime when) {
    MileageRate? best;

    for (final MileageRate rate in published) {
      if (rate.jurisdiction != jurisdiction) continue;
      if (rate.effectiveFrom.isAfter(when)) continue;
      if (best != null && rate.effectiveFrom.isBefore(best.effectiveFrom)) {
        continue;
      }

      best = rate;
    }

    return best;
  }
}

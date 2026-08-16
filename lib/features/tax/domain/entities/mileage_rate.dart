import '../enums/tax_jurisdiction.dart';

/// One band of a mileage rate: a rate that applies up to a distance.
///
/// The UK pays 45p for the first 10,000 business miles and 25p after that, so
/// a single rate cannot express it. The US has one band with no ceiling, and
/// modelling that as a one-element list rather than a special case is what
/// keeps the calculator free of `if (isUk)`.
class MileageBand {
  const MileageBand({
    required this.upToDistance,
    required this.rateMinorHundredths,
  });

  /// The distance this band runs to, or null for "everything above the last
  /// band". Cumulative from zero, not a width.
  final double? upToDistance;

  /// Hundredths of a minor unit per [MileageUnit] — so 67 cents a mile is
  /// `6700` and 45p is `4500`.
  ///
  /// **Integer, like every other amount in this app** (hard rule 4); a year
  /// of mileage summed in doubles drifts visibly. Scaled by [rateScale]
  /// rather than held in whole minor units because a rate is not itself an
  /// amount and the authorities do publish fractions of one: the IRS set 72.5
  /// cents for the first half of 2026.
  final int rateMinorHundredths;

  /// What [rateMinorHundredths] is scaled by. The field's own unit, not
  /// configuration about it.
  static const int rateScale = 100;
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
/// **Verified against irs.gov and gov.uk on 16 August 2026.** A wrong rate
/// here is a wrong tax return, so re-check before each filing season and add
/// a new dated entry rather than editing an old one — a past year must keep
/// deducting at the rate that applied to it.
final class MileageRateConstant {
  static final List<MileageRate> published = <MileageRate>[
    // IRS standard mileage rate, business use. One band, no ceiling.
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2024),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinorHundredths: 6700),
      ],
    ),
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2025),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinorHundredths: 7000),
      ],
    ),
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2026),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinorHundredths: 7250),
      ],
    ),
    // The IRS raised the rate mid-year, which is why a journey is rated by its
    // own date and a year is not rated by one figure.
    MileageRate(
      jurisdiction: TaxJurisdiction.us,
      effectiveFrom: DateTime(2026, DateTime.july),
      bands: const <MileageBand>[
        MileageBand(upToDistance: null, rateMinorHundredths: 7600),
      ],
    ),
    // HMRC approved mileage allowance payments, cars and vans. Two bands, and
    // the 10,000-mile threshold is per tax year rather than per journey.
    MileageRate(
      jurisdiction: TaxJurisdiction.uk,
      effectiveFrom: DateTime(2011, DateTime.april, 6),
      bands: const <MileageBand>[
        MileageBand(upToDistance: 10000, rateMinorHundredths: 4500),
        MileageBand(upToDistance: null, rateMinorHundredths: 2500),
      ],
    ),
    // First change since 2011: the first band went to 55p, the second stayed.
    MileageRate(
      jurisdiction: TaxJurisdiction.uk,
      effectiveFrom: DateTime(2026, DateTime.april, 6),
      bands: const <MileageBand>[
        MileageBand(upToDistance: 10000, rateMinorHundredths: 5500),
        MileageBand(upToDistance: null, rateMinorHundredths: 2500),
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

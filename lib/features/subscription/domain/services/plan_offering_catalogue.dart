import '../entities/plan_offering.dart';

/// What the paywall shows, out of whatever the store handed back.
///
/// **The store's order is not a promise.** RevenueCat returns an offering's
/// packages in dashboard order, which the owner can rearrange without touching
/// the app — so the recommended option would move between launches, and the
/// seller would be reading a different sheet each time. The order is imposed
/// here, and the screen renders the list it is given.
final class PlanOfferingCatalogue {
  /// The period the sheet opens on. Yearly: it is the cheaper way to hold
  /// Premium for a year, and the option a paywall with no recommendation
  /// leaves the seller to work out for themselves.
  static const BillingPeriod recommended = BillingPeriod.yearly;

  /// The order the two options are laid out in, left to right.
  static const List<BillingPeriod> _display = <BillingPeriod>[
    BillingPeriod.yearly,
    BillingPeriod.monthly,
  ];

  /// One offering per period, in [_display] order.
  ///
  /// A period appearing twice keeps the first: two products of the same
  /// duration is a dashboard mistake, and rendering both is two identical
  /// cards the seller has to choose between.
  static List<PlanOffering> ordered(List<PlanOffering> offerings) {
    final Map<BillingPeriod, PlanOffering> byPeriod =
        <BillingPeriod, PlanOffering>{};

    for (final PlanOffering offering in offerings) {
      byPeriod.putIfAbsent(offering.period, () => offering);
    }

    return <PlanOffering>[
      for (final BillingPeriod period in _display)
        if (byPeriod[period] case final PlanOffering offering) offering,
    ];
  }

  /// What a selected period buys.
  ///
  /// Falls back to the first offering on sale rather than to null: a store
  /// that sells monthly only would otherwise leave the sheet's one button
  /// dead while two prices are on screen.
  static PlanOffering? selected(
    List<PlanOffering> offerings,
    BillingPeriod period,
  ) {
    for (final PlanOffering offering in offerings) {
      if (offering.period == period) return offering;
    }

    return offerings.isEmpty ? null : offerings.first;
  }

  /// Whether this option is the one the paywall recommends. Only ever true
  /// alongside another option — a lone product is not a better deal than
  /// anything.
  static bool isBestValue(PlanOffering offering, List<PlanOffering> offerings) =>
      offerings.length > 1 && offering.period == recommended;
}

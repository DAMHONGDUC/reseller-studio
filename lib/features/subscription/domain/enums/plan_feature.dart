import 'seller_plan.dart';

/// A capability a plan either includes or does not (plan §27).
///
/// **A closed enum rather than a string key**, so the paywall, the gate and
/// the settings screen cannot disagree about what a feature is called, and so
/// adding one fails to compile until [requiredPlan] answers for it.
/// **Only capabilities something in the app refuses may live here** — owner's
/// rule. The paywall is generated from this enum, so a value with no gate
/// behind it is a promise the product does not keep: `advancedAnalytics`,
/// `reports`, `automation`, `team`, `multipleWorkspaces` and
/// `advancedPermissions` were all sold on the paywall and gated nowhere, and
/// one of them — multiple businesses — was the workspace ceiling listed a
/// second time under another name. `payoutReconciliation` went when payout
/// chasing became free. They come back the day a gate does.
enum PlanFeature {
  /// Handing the records to somebody else: the tax pack, and every CSV.
  ///
  /// **Owner's rule: export is the only thing Premium sells**
  /// (`docs/rules/SUBSCRIPTION.md`). One value rather than one per button,
  /// because "can this seller take their figures out of the app" has a single
  /// answer — and two names for one rule is how the tax summary came to be
  /// free on Reports while the identical tax pack was sold on Tax.
  export;

  /// The cheapest plan that includes this.
  ///
  /// The whole plan-to-feature table, in one switch. Gates ask
  /// `plan.isAtLeast(feature.requiredPlan)`, never a list of plans, so a
  /// a future tier slots in here and nowhere else.
  SellerPlan get requiredPlan => switch (this) {
    PlanFeature.export => SellerPlan.premium,
  };
}

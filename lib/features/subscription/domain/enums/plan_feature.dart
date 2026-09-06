import 'seller_plan.dart';

/// A capability a plan either includes or does not (plan §27).
///
/// **A closed enum rather than a string key**, so the paywall, the gate and
/// the settings screen cannot disagree about what a feature is called, and so
/// adding one fails to compile until [requiredPlan] answers for it.
enum PlanFeature {
  advancedAnalytics,
  reports,
  automation,
  team,
  multipleWorkspaces,
  advancedPermissions,

  /// A year's summary, sales and expenses handed over in one action, with the
  /// line saying how complete it is.
  ///
  /// **The capability Premium is really sold on.** It has a deadline the
  /// seller cannot move, its alternative is a weekend of spreadsheet work or
  /// an accountant's fee, and it is worth exactly nothing until a year of
  /// records exists — which is why the ceiling that used to stop them at
  /// fifty items was blocking the reason to buy.
  taxExport,

  /// What each marketplace still owes, and which sales it has sat on.
  ///
  /// The only capability that hands money back rather than asking for work.
  payoutReconciliation;

  /// The cheapest plan that includes this.
  ///
  /// The whole plan-to-feature table, in one switch. Gates ask
  /// `plan.isAtLeast(feature.requiredPlan)`, never a list of plans, so a
  /// a future tier slots in here and nowhere else.
  SellerPlan get requiredPlan => switch (this) {
    PlanFeature.advancedAnalytics ||
    PlanFeature.reports ||
    PlanFeature.automation ||
    PlanFeature.team ||
    PlanFeature.multipleWorkspaces ||
    PlanFeature.advancedPermissions ||
    PlanFeature.taxExport ||
    PlanFeature.payoutReconciliation => SellerPlan.premium,
  };
}

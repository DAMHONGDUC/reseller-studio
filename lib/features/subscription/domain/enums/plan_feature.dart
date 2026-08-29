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
  advancedPermissions;

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
    PlanFeature.advancedPermissions => SellerPlan.premium,
  };
}

import '../entities/plan_limits.dart';
import 'seller_plan.dart';

/// A countable thing a plan can put a ceiling on (plan §27).
///
/// **It exists so a ceiling can be iterated.** `PlanLimits` holds three
/// fields and a field list cannot be walked, so the meter that shows a seller
/// what is left had no way to ask "which allowances are capped?" without
/// naming all three at the call site — which is the copy that goes stale.
///
/// A new allowance is added here and in [ceilingIn] together; the switch is
/// what fails to compile until it is.
enum PlanAllowance {
  items,
  orders,
  workspaces;

  /// The ceiling this plan puts on the allowance, or null where there is
  /// none — `null` means unlimited, exactly as it does on [PlanLimits].
  int? ceilingIn(PlanLimits limits) => switch (this) {
    PlanAllowance.items => limits.items,
    PlanAllowance.orders => limits.orders,
    PlanAllowance.workspaces => limits.workspaces,
  };
}

/// How an allowance and its meter read.
///
/// Same reason as `SellerPlanDisplay`: the meter is drawn from
/// `core/widgets/`, which may reach a feature's `domain/` and nothing else.
extension PlanAllowanceDisplay on PlanAllowance {
  /// "Businesses" rather than "workspaces": that is what the app calls one
  /// everywhere the seller can read it.
  String get label => switch (this) {
    PlanAllowance.items => 'Items',
    PlanAllowance.orders => 'Orders',
    PlanAllowance.workspaces => 'Businesses',
  };

  /// The meter's headline: which allowance, and whose ceiling it is.
  ///
  /// **It names the plan on purpose.** The meter is drawn under screen titles
  /// that already say the allowance — Businesses, Orders — and a card headed
  /// with the same word says nothing twice; the plan is the part the seller
  /// cannot read off the chrome.
  String meterTitle(SellerPlan plan) => '$label on ${plan.label}';

  /// The two counts as one string. Not a percentage: "1/1" says how many are
  /// left at a glance, where "100%" has to be worked out.
  String countLabel({required int used, required int limit}) => '$used/$limit';
}

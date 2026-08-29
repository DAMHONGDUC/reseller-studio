import '../entities/plan_limits.dart';
import '../enums/plan_feature.dart';
import '../enums/seller_plan.dart';

/// Why an action was refused, so the caller can say something useful.
///
/// A bool would make every call site invent its own message, and the message
/// is the whole product here: naming the Free ceiling is a reason to upgrade,
/// "not allowed" is a reason to leave.
enum PlanBlock {
  /// Allowed. Named rather than represented by null so a `switch` over the
  /// result is exhaustive.
  none,
  itemLimit,
  orderLimit,
  workspaceLimit,
  featureLocked,
}

/// The one place that decides what a plan may do (plan §27).
///
/// **Pure, and it takes the current counts rather than reading them.** A gate
/// that fetched its own numbers could not be unit-tested at the boundaries,
/// and the boundaries are the only interesting part of a limit.
///
/// **This is not the security boundary.** `firestore.rules`, reading the
/// entitlement a Cloud Function mirrored, is — the same relationship
/// `MemberRole` has with permissions. This decides what the UI offers.
final class PlanGate {
  /// Whether one more item may be created.
  ///
  /// **Compares against the limit, never against the limit minus one.** Off
  /// by one here makes the advertised last slot unusable.
  static PlanBlock canAddItem(SellerPlan plan, {required int currentItems}) =>
      _underLimit(currentItems, PlanLimits.of(plan).items)
      ? PlanBlock.none
      : PlanBlock.itemLimit;

  static PlanBlock canAddOrder(SellerPlan plan, {required int currentOrders}) =>
      _underLimit(currentOrders, PlanLimits.of(plan).orders)
      ? PlanBlock.none
      : PlanBlock.orderLimit;

  static PlanBlock canAddWorkspace(
    SellerPlan plan, {
    required int currentWorkspaces,
  }) => _underLimit(currentWorkspaces, PlanLimits.of(plan).workspaces)
      ? PlanBlock.none
      : PlanBlock.workspaceLimit;

  /// Whether a plan includes a capability at all.
  static bool has(SellerPlan plan, PlanFeature feature) =>
      plan.isAtLeast(feature.requiredPlan);

  /// The cheapest plan that clears [block], or null where nothing is wrong.
  ///
  /// What the paywall opens on. Every paid capability belongs to Premium, so
  /// a blocked seller never has to compare feature tiers.
  static SellerPlan? upgradeFor(PlanBlock block, {required SellerPlan from}) =>
      block == PlanBlock.none ? null : SellerPlan.premium;

  /// Null limit means unlimited — see `PlanLimits`.
  static bool _underLimit(int current, int? limit) =>
      limit == null || current < limit;
}

import '../entities/plan_limits.dart';
import '../enums/plan_feature.dart';
import '../enums/seller_plan.dart';

/// Why an action was refused, so the caller can say something useful.
///
/// A bool would make every call site invent its own message, and the message
/// is the whole product here: "Free holds 50 items" is a reason to upgrade,
/// "not allowed" is a reason to leave.
enum PlanBlock {
  /// Allowed. Named rather than represented by null so a `switch` over the
  /// result is exhaustive.
  none,
  itemLimit,
  listingLimit,
  marketplaceLimit,
  memberLimit,
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
  /// by one here is a seller on Free who can hold 49 items and cannot say
  /// why.
  static PlanBlock canAddItem(SellerPlan plan, {required int currentItems}) =>
      _underLimit(currentItems, PlanLimits.of(plan).items)
      ? PlanBlock.none
      : PlanBlock.itemLimit;

  static PlanBlock canListItem(
    SellerPlan plan, {
    required int currentActiveListings,
  }) => _underLimit(currentActiveListings, PlanLimits.of(plan).activeListings)
      ? PlanBlock.none
      : PlanBlock.listingLimit;

  static PlanBlock canConnectMarketplace(
    SellerPlan plan, {
    required int currentMarketplaces,
  }) => _underLimit(currentMarketplaces, PlanLimits.of(plan).marketplaces)
      ? PlanBlock.none
      : PlanBlock.marketplaceLimit;

  static PlanBlock canInviteMember(
    SellerPlan plan, {
    required int currentMembers,
  }) {
    // Team is a Business capability before it is a seat count: Free and Pro
    // are one-person plans, so the honest block is "this plan has no team",
    // not "you have run out of seats".
    if (!has(plan, PlanFeature.team)) return PlanBlock.featureLocked;

    return _underLimit(currentMembers, PlanLimits.of(plan).members)
        ? PlanBlock.none
        : PlanBlock.memberLimit;
  }

  /// Whether a plan includes a capability at all.
  static bool has(SellerPlan plan, PlanFeature feature) =>
      plan.isAtLeast(feature.requiredPlan);

  /// The cheapest plan that clears [block], or null where nothing is wrong.
  ///
  /// What the paywall opens on. Sending a Free seller who hit the item limit
  /// straight to Pro beats a price grid they have to read.
  static SellerPlan? upgradeFor(PlanBlock block, {required SellerPlan from}) =>
      switch (block) {
        PlanBlock.none => null,
        PlanBlock.itemLimit || PlanBlock.listingLimit => SellerPlan.pro,
        PlanBlock.marketplaceLimit => _next(from),
        PlanBlock.memberLimit || PlanBlock.featureLocked => SellerPlan.business,
      };

  /// Null limit means unlimited — see `PlanLimits`.
  static bool _underLimit(int current, int? limit) =>
      limit == null || current < limit;

  /// One tier up, or the top one if there is nowhere left to go.
  static SellerPlan _next(SellerPlan from) =>
      from.index + 1 < SellerPlan.values.length
      ? SellerPlan.values[from.index + 1]
      : SellerPlan.business;
}

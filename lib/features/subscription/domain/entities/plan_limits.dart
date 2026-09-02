import '../enums/seller_plan.dart';

/// How much of the app a plan lets a seller hold (plan §27).
///
/// **`null` means unlimited, and it is the only meaning it has here.** That
/// is deliberately not `Money?`'s convention — an amount of null is "not
/// known" (hard rule 4) — because a limit is always known: either there is a
/// ceiling or there is not. A sentinel like `-1` would have to be remembered
/// at every comparison; null forces the question at the type.
class PlanLimits {
  const PlanLimits({
    required this.items,
    required this.orders,
    required this.workspaces,
  });

  /// Items on hand. Nothing is deleted when a seller downgrades — see
  /// `PlanGate`, which blocks the next *create* and never the existing rows.
  final int? items;

  final int? orders;
  final int? workspaces;

  /// The table itself. One place, so a limit cannot be quoted differently by
  /// the paywall and by the gate that enforces it.
  ///
  /// The owner-approved ceilings. They live here rather than in prose because
  /// a copied number goes stale silently; paywall copy and gates read this map.
  ///
  /// **Free no longer counts records, and that is the owner's decision.** It
  /// held 50 items and 30 orders, and the problem was what that ceiling
  /// blocked: every figure this app is bought for — sell-through, ROI by
  /// source, payout reconciliation, the tax pack — is meaningless at forty
  /// items. The ceiling stopped a seller exactly at the point their data was
  /// about to start being worth something, so they left before seeing the
  /// reason to pay.
  ///
  /// **What Premium sells instead is the answers**, not permission to keep
  /// typing: `PlanFeature.taxExport`, `payoutReconciliation`,
  /// `advancedAnalytics`, `team`. One business stays the Free ceiling because
  /// a second one is a second business, not a bigger one.
  static const Map<SellerPlan, PlanLimits> byPlan = <SellerPlan, PlanLimits>{
    SellerPlan.free: PlanLimits(items: null, orders: null, workspaces: 1),
    SellerPlan.premium: PlanLimits(items: null, orders: null, workspaces: null),
  };

  /// Never null: every plan has a row, and a missing one is a programming
  /// error rather than a reason to let the app through ungated.
  static PlanLimits of(SellerPlan plan) => byPlan[plan]!;
}

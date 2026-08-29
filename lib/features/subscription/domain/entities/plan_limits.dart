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
  static const Map<SellerPlan, PlanLimits> byPlan = <SellerPlan, PlanLimits>{
    SellerPlan.free: PlanLimits(items: 50, orders: 30, workspaces: 1),
    SellerPlan.premium: PlanLimits(items: null, orders: null, workspaces: null),
  };

  /// Never null: every plan has a row, and a missing one is a programming
  /// error rather than a reason to let the app through ungated.
  static PlanLimits of(SellerPlan plan) => byPlan[plan]!;
}

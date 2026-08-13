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
    required this.activeListings,
    required this.marketplaces,
    required this.members,
  });

  /// Items on hand. Nothing is deleted when a seller downgrades — see
  /// `PlanGate`, which blocks the next *create* and never the existing rows.
  final int? items;

  final int? activeListings;
  final int? marketplaces;

  /// Seats, the seller included. Free and Pro are one person.
  final int? members;

  /// The table itself. One place, so a limit cannot be quoted differently by
  /// the paywall and by the gate that enforces it.
  ///
  /// **These numbers are a first proposal, not a priced decision.** They are
  /// here rather than in a document because a number in prose goes stale
  /// silently; changing them is a one-line edit and needs no code change
  /// anywhere else.
  static const Map<SellerPlan, PlanLimits> byPlan = <SellerPlan, PlanLimits>{
    SellerPlan.free: PlanLimits(
      items: 50,
      activeListings: 25,
      marketplaces: 1,
      members: 1,
    ),
    SellerPlan.pro: PlanLimits(
      items: null,
      activeListings: null,
      marketplaces: 5,
      members: 1,
    ),
    SellerPlan.business: PlanLimits(
      items: null,
      activeListings: null,
      marketplaces: null,
      members: 10,
    ),
  };

  /// Never null: every plan has a row, and a missing one is a programming
  /// error rather than a reason to let the app through ungated.
  static PlanLimits of(SellerPlan plan) => byPlan[plan]!;
}

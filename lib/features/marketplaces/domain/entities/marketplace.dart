/// A place this business sells — eBay, a Sunday market stall, a friend.
///
/// **A record the seller owns, not an enum** — owner's rule, and it replaced a
/// closed list of seven. A reseller's platforms are theirs: Vinted in one
/// country, Grailed in another, "Facebook" and "Instagram" for half of them,
/// and a stall that has no website at all. A closed enum meant every one of
/// those sold as "Other", which is the row analytics cannot answer a question
/// about.
///
/// **It is per business** (`workspaces/{id}/marketplaces/{id}`), because two
/// businesses in one account sell in different places and pay different rates.
/// A new business is seeded with `MarketplaceConstant.defaults`.
///
/// **Soft-deleted** (hard rule 15): listings and orders point at one by id, so
/// hard-deleting would orphan them and take the marketplace out of every past
/// figure that was already reported.
class Marketplace {
  const Marketplace({
    required this.id,
    required this.name,
    required this.feeRate,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;

  /// What the seller calls it. **Not localized** — a platform's name is a
  /// brand, and a stall's name is whatever the seller typed.
  final String name;

  /// The platform's cut, as a fraction of the sale price.
  ///
  /// **An estimate for planning, never accounting.** A fee an order actually
  /// reported is a fact and always wins — see `PayoutReconciliation.expected`,
  /// which falls back to this only when `fees` is null.
  final double feeRate;

  final DateTime createdAt;

  /// Set rather than removed, so a listing or an order that names this
  /// marketplace still renders its name.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Marketplace copyWith({String? name, double? feeRate, DateTime? deletedAt}) =>
      Marketplace(
        id: id,
        name: name ?? this.name,
        feeRate: feeRate ?? this.feeRate,
        createdAt: createdAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

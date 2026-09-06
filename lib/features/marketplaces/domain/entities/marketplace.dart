import '../../../../core/theme/app_tag_hue.dart';

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
/// businesses in one account sell in different places. A new business is
/// seeded with `MarketplaceConstant.defaults`.
///
/// **It carries no fee rate.** What a platform charges is measured from each
/// order's payout (hard rule 3); the one planning assumption left lives on the
/// workspace (`Workspace.planningFeeRate`).
///
/// **Soft-deleted** (hard rule 15): listings and orders point at one by id, so
/// hard-deleting would orphan them and take the marketplace out of every past
/// figure that was already reported.
///
/// **It carries a colour**, which is the one place this entity reaches into
/// `core/theme/` — `AppTagHue` is a display enum in its own file, the same
/// exception `ItemStatus` uses (root `CLAUDE.md`).
class Marketplace {
  const Marketplace({
    required this.id,
    required this.name,
    required this.createdAt,
    this.hue = AppTagHue.grey,
    this.deletedAt,
  });

  final String id;

  /// What the seller calls it. **Not localized** — a platform's name is a
  /// brand, and a stall's name is whatever the seller typed.
  final String name;

  final DateTime createdAt;

  /// How every row that names this marketplace is tagged.
  ///
  /// Grey is the default because a marketplace the seller just added has no
  /// colour opinion yet — the seeded five each start somewhere else, so the
  /// colours are visible without anybody configuring them.
  final AppTagHue hue;

  /// Set rather than removed, so a listing or an order that names this
  /// marketplace still renders its name.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Marketplace copyWith({String? name, AppTagHue? hue, DateTime? deletedAt}) =>
      Marketplace(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        hue: hue ?? this.hue,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

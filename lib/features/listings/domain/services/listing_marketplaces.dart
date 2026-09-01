import '../../../marketplaces/domain/enums/marketplace.dart';
import '../entities/listing.dart';

/// Which marketplaces a set of listings covers, answered in one place.
///
/// Three screens ask it — the inventory row's badge, the record-sale row, and
/// the mark-sold sheet deciding which platforms it may offer — and each was
/// about to write its own `map().toSet()` over a list it had filtered by item
/// id itself. Two of them disagreeing about whether a draft listing counts is
/// the bug this removes.
///
/// **Every listing counts, whatever its status.** Publishing writes drafts
/// (`lib/features/inventory/CLAUDE.md`), so a live-only count would answer
/// zero for every item in the app.
final class ListingMarketplaces {
  /// The distinct platforms [listings] name, in the order they first appear.
  static Set<Marketplace> of(List<Listing> listings) => <Marketplace>{
    for (final Listing listing in listings) listing.marketplace,
  };

  /// The distinct platforms carrying [itemId], out of a list of every
  /// listing the business has.
  static Set<Marketplace> forItem(List<Listing> listings, String itemId) =>
      <Marketplace>{
        for (final Listing listing in listings)
          if (listing.itemId == itemId) listing.marketplace,
      };

  /// How many platforms carry [itemId]. Zero is a fact — the item is on
  /// none — never a missing figure.
  static int countFor(List<Listing> listings, String itemId) =>
      forItem(listings, itemId).length;

  /// The platform keys [listings] name — each enum's own `name`, which is
  /// also the id a seeded workspace marketplace carries.
  ///
  /// Strings rather than the enum so a caller that already has the
  /// marketplace *records* in scope can ask this without importing a second
  /// type called `Marketplace`. `MarketplaceMatching` is what turns them back
  /// into records.
  static Set<String> keys(List<Listing> listings) => <String>{
    for (final Marketplace marketplace in of(listings)) marketplace.name,
  };
}

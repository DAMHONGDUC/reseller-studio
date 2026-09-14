import '../../../../core/money/money.dart';
import '../entities/listing.dart';

/// Questions about a set of listings' prices, answered in one place.
///
/// The item has no price of its own (`lib/features/inventory/CLAUDE.md`), so
/// every screen that used to seed a field from `Item.askingPrice` asks the
/// listings instead — and two of them asking it two ways is how the List
/// screen and the reprice sheet would come to disagree about what "the price"
/// of a cross-listed item is.
final class ListingPricing {
  /// The one price every listing agrees on, or null when they do not.
  ///
  /// **Null is the important case.** Pre-filling a field with the number that
  /// belongs to one of four marketplaces, and then applying it to all four,
  /// is a silent reprice nobody asked for.
  static Money? sharedPrice(List<Listing> listings) {
    if (listings.isEmpty) return null;

    final Money first = listings.first.price;

    return listings.every((Listing listing) => listing.price == first)
        ? first
        : null;
  }

  /// Each platform's own price, keyed by the marketplace enum's `name` —
  /// which is also the id a seeded workspace marketplace record carries.
  ///
  /// **The first listing on a platform wins.** Nothing in the app writes a
  /// second listing on the same marketplace (the cross-list screen ticks a
  /// platform the item is already on rather than offering it again), so a
  /// duplicate is a repair case, and the older record is the one every other
  /// screen is already showing.
  ///
  /// Keyed by the marketplace record's id, which is what a listing carries.
  static Map<String, Money> byMarketplace(List<Listing> listings) {
    final Map<String, Money> prices = <String, Money>{};

    for (final Listing listing in listings) {
      prices.putIfAbsent(listing.marketplaceId, () => listing.price);
    }

    return prices;
  }

  /// The highest price any of them carries, or null when there are none.
  ///
  /// **For seeding a box the seller will confirm**, never for a write applied
  /// to all of them — that is what [sharedPrice] is for. A blank field on an
  /// item that is live at three prices is worse than the top one: the seller
  /// retypes a number the app already knew, and the number they were most
  /// likely reaching for is the ask, not the discount.
  ///
  /// Two currencies cannot be compared (hard rule 4), so the first listing's
  /// currency wins and the rest are ignored — an item cross-listed in two
  /// currencies has no single top price to offer.
  static Money? topPrice(List<Listing> listings) {
    if (listings.isEmpty) return null;

    final String currency = listings.first.price.currency;
    final Iterable<Money> comparable = listings
        .map((Listing listing) => listing.price)
        .where((Money price) => price.currency == currency);

    return comparable.reduce((Money a, Money b) => b.minor > a.minor ? b : a);
  }
}

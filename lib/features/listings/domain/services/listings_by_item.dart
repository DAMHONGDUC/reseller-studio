import '../entities/listing.dart';

/// Every listing the business has, keyed by the item it belongs to.
///
/// **Grouped once per list, never watched per row** — a family subscription on
/// every card is one listener each and a rebuild of the whole list on any
/// listing write. Extracted on its second copy: Inventory's list and the sale
/// picker both draw `ItemCard`, which takes one item's listings.
final class ListingsByItem {
  static Map<String, List<Listing>> group(List<Listing> listings) {
    final Map<String, List<Listing>> byItem = <String, List<Listing>>{};

    for (final Listing listing in listings) {
      byItem.putIfAbsent(listing.itemId, () => <Listing>[]).add(listing);
    }

    return byItem;
  }
}

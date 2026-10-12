import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/enums/item_status.dart';
import '../entities/listing.dart';

/// Listings still live on an item that can no longer be sold — the
/// "delist after sale" step of cross-listing (plan §13).
///
/// The app talks to no marketplace by itself yet, so it cannot take them
/// down; what it can do is say which ones are left, before a second buyer
/// pays for a jacket that has already gone.
final class ListingsToEnd {
  static List<Listing> after({
    required List<Listing> listings,
    required Map<String, Item> items,
  }) => <Listing>[
    for (final Listing listing in listings)
      if (listing.status.isLive && _gone(items[listing.itemId])) listing,
  ];

  /// Sold out or withdrawn. A dropshipped item never sells out — a supplier
  /// ships each sale — so it is never gone by selling.
  static bool _gone(Item? item) =>
      item != null &&
      !item.isDropship &&
      (item.status == ItemStatus.sold || item.status == ItemStatus.archived);
}

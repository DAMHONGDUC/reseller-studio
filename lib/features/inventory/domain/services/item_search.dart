import '../entities/item.dart';

/// What "this row matches what the seller typed" means — once, for every
/// screen that filters items.
///
/// Inventory's list and the record-sale picker are the two today, and they
/// have to agree: a seller who finds an item by its SKU on one screen and not
/// on the other reads that as the item being gone.
final class ItemSearch {
  /// Whether [item] matches [query]. An empty query matches everything, so a
  /// caller can pass the field's raw text.
  ///
  /// **Title, SKU and barcode — the three things a seller has to hand** (plan
  /// §21). Notes are deliberately not searched: they are long, and matching
  /// them makes the results look random to someone who typed a SKU.
  static bool matches(Item item, String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;

    return item.title.toLowerCase().contains(needle) ||
        (item.sku?.toLowerCase().contains(needle) ?? false) ||
        (item.barcode?.toLowerCase().contains(needle) ?? false);
  }
}

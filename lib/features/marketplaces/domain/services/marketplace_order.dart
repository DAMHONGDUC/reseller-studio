import '../enums/marketplace.dart';

/// The order marketplaces are drawn in, wherever a list of them is drawn.
///
/// **The enum's declaration order is the canonical one.** It is already what
/// the cross-list screen draws `Marketplace.values` in, so adopting it costs
/// no screen its current shape. What it fixes is the lists that had no order
/// at all: a query hands back a document order, so an item live on eBay and
/// Depop read "Depop, eBay" on its detail screen and "eBay … Depop" on the
/// next one — the same two marketplaces, twice, in two orders.
///
/// **Ordering by marketplace is not ranking by one.** Analytics sorts its
/// breakdown by what each platform earned, which is an answer rather than a
/// list, and stays as it is.
final class MarketplaceOrder {
  /// [items] in canonical order, as a new list — a stream's value is not
  /// something to sort in place.
  static List<T> sort<T>(Iterable<T> items, Marketplace Function(T item) of) =>
      <T>[...items]
        ..sort((T a, T b) => of(a).index.compareTo(of(b).index));
}

import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../orders/domain/entities/order.dart';

/// What the seller got for this thing last time.
class SoldBefore {
  const SoldBefore({
    required this.title,
    required this.salePrice,
    required this.soldAt,
    required this.timesSold,
  });

  final String title;

  /// What that unit went for — the line's own price, not the order total: a
  /// two-item order would otherwise suggest twice the going rate.
  final Money salePrice;

  final DateTime soldAt;

  /// How many separate sales matched. Two is a pattern, one is an anecdote,
  /// and the screen says which.
  final int timesSold;
}

/// Has this been through the business before, and what did it fetch?
///
/// **The whole answer comes from the seller's own records**, which is what
/// makes it work in a shop on one bar of signal — no marketplace API, no comps
/// service. It points the "SOURCE BETTER" end of the lifecycle back at the
/// start of it.
///
/// Pure, and it takes the rows rather than reading them: the interesting cases
/// are a code matching an item that never sold and one matching several sales,
/// and a service that fetched its own data could not be tested at either.
final class SoldBeforeLookup {
  /// The most recent sale of anything carrying [code], or null.
  ///
  /// Matches a barcode **or** a SKU, the same way the scanner screen does: a
  /// seller who typed the code into the other box still finds their history.
  static SoldBefore? find({
    required String code,
    required List<Item> items,
    required List<Order> orders,
  }) {
    final String needle = code.trim();

    if (needle.isEmpty) return null;

    final Set<String> itemIds = items
        .where((Item item) => item.barcode == needle || item.sku == needle)
        .map((Item item) => item.id)
        .toSet();

    if (itemIds.isEmpty) return null;

    final List<_Sale> sales = <_Sale>[];

    for (final Order order in orders) {
      if (!order.status.countsAsRevenue) continue;

      for (final OrderLine line in order.lines) {
        if (!itemIds.contains(line.itemId)) continue;

        sales.add(
          _Sale(
            title: line.title,
            price: line.unitPrice,
            when: order.orderedAt,
          ),
        );
      }
    }

    if (sales.isEmpty) return null;

    sales.sort((_Sale a, _Sale b) => b.when.compareTo(a.when));

    final _Sale latest = sales.first;

    return SoldBefore(
      title: latest.title,
      salePrice: latest.price,
      soldAt: latest.when,
      timesSold: sales.length,
    );
  }
}

class _Sale {
  const _Sale({required this.title, required this.price, required this.when});

  final String title;
  final Money price;
  final DateTime when;
}

import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/enums/item_status.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../pricing/domain/services/profit_calculator.dart';

/// What the business sold (plan §9, Sales section).
///
/// **Average selling price is per unit; average order value is per order.**
/// They are the same number only when every order has one line, and a seller
/// who bundles needs both — one says whether the pricing is right, the other
/// says whether the basket is.
class SalesMetrics {
  const SalesMetrics({
    required this.revenue,
    required this.orderCount,
    required this.unitsSold,
    required this.averageOrderValue,
    required this.averageSellingPrice,
    required this.refunded,
  });

  /// Fold the orders that count as revenue.
  ///
  /// A cancelled order never earned anything and a refunded one gave it back,
  /// so neither is counted — otherwise these figures disagree with the
  /// seller's bank.
  factory SalesMetrics.from({
    required List<Order> orders,
    required String currency,
  }) {
    final Money zero = Money.zero(currency);

    final List<Order> counted = orders
        .where((Order order) => order.status.countsAsRevenue)
        .toList();

    final Money? revenue = counted
        .map((Order order) => order.salePrice - (order.refund ?? zero))
        .totalOrNull();

    final int units = counted.fold(
      0,
      (int total, Order order) => total + order.unitCount,
    );

    return SalesMetrics(
      revenue: revenue,
      orderCount: counted.length,
      unitsSold: units,
      averageOrderValue: _divide(revenue, counted.length),
      averageSellingPrice: _divide(revenue, units),
      refunded: orders
          .map((Order order) => order.refund)
          .whereType<Money>()
          .totalOrNull(),
    );
  }

  final Money? revenue;
  final int orderCount;
  final int unitsSold;
  final Money? averageOrderValue;
  final Money? averageSellingPrice;

  /// What went back to buyers. Null when nothing has been refunded — which is
  /// different from zero refunds having been recorded.
  final Money? refunded;

  /// Null rather than a division by zero, so an empty period renders `—`.
  static Money? _divide(Money? total, int by) {
    if (total == null || by == 0) return null;

    return Money(total.minor ~/ by, total.currency);
  }
}

/// What the business is holding, and how fast it moves (plan §9, Inventory).
class InventoryMetrics {
  const InventoryMetrics({
    required this.value,
    required this.onHandCount,
    required this.listedCount,
    required this.staleCount,
    required this.soldCount,
    required this.sellThrough,
    required this.averageDaysToSell,
    required this.averageAgeDays,
  });

  factory InventoryMetrics.from({
    required List<Item> items,
    required DateTime now,
    required Duration staleThreshold,
  }) {
    final List<Item> onHand = items
        .where((Item item) => item.status.isOnHand)
        .toList();

    final List<Item> sold = items
        .where((Item item) => item.status == ItemStatus.sold)
        .toList();

    final List<Item> listed = items
        .where((Item item) => item.status.isOnHand && item.listedAt != null)
        .toList();

    // Days from listing to sale, over the sold items that recorded both. An
    // item sold straight off the shelf never had a listing date and cannot
    // answer this — including it as zero would flatter the average.
    final List<int> daysToSell = sold
        .where((Item item) => item.listedAt != null && item.soldAt != null)
        .map((Item item) => item.soldAt!.difference(item.listedAt!).inDays)
        .toList();

    final List<int> ages = onHand
        .map((Item item) => now.difference(item.createdAt).inDays)
        .toList();

    return InventoryMetrics(
      value: onHand.map((Item item) => item.inventoryValue).totalOfKnown(),
      onHandCount: onHand.length,
      listedCount: listed.length,
      staleCount: listed
          .where(
            (Item item) => StaleInventoryPolicy.isStale(
              item.listedAt,
              now: now,
              threshold: staleThreshold,
            ),
          )
          .length,
      soldCount: sold.length,
      // Sold over everything ever held. Null when nothing has been held at
      // all, which is a new workspace rather than a sell-through of zero.
      sellThrough: items.isEmpty ? null : sold.length / items.length,
      averageDaysToSell: _average(daysToSell),
      averageAgeDays: _average(ages),
    );
  }

  final Money? value;
  final int onHandCount;
  final int listedCount;
  final int staleCount;
  final int soldCount;

  /// Sold as a fraction of everything ever held.
  final double? sellThrough;

  /// How long a sold item was listed before it went. Null when no sold item
  /// recorded both dates.
  final double? averageDaysToSell;

  /// How long the current stock has been sitting.
  final double? averageAgeDays;

  static double? _average(List<int> values) {
    if (values.isEmpty) return null;

    return values.reduce((int a, int b) => a + b) / values.length;
  }
}

/// One category's contribution (plan §9, Category section).
///
/// **Revenue comes from the orders, not from asking prices.** An asking price
/// is what the seller hoped for; only a sale says what a category is worth.
class CategoryPerformance {
  const CategoryPerformance({
    required this.categoryId,
    required this.itemCount,
    required this.soldCount,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  final String categoryId;
  final int itemCount;
  final int soldCount;
  final Money? revenue;

  /// What the sold items cost. Null when any of them has no recorded cost —
  /// hard rule 5: say nothing rather than something wrong.
  final Money? cost;

  final Money? profit;

  /// Return on what was spent in this category, or null when nothing was.
  double? get roi {
    final Money? made = profit;
    final Money? paid = cost;

    if (made == null || paid == null || paid.isZero) return null;

    return made.ratioOf(paid);
  }

  /// Sold as a fraction of what was bought into this category.
  double? get sellThrough => itemCount == 0 ? null : soldCount / itemCount;
}

import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/supplier_order.dart';

/// Revenue and gross profit for one side of the business.
class FulfilmentFigures {
  const FulfilmentFigures({
    required this.lines,
    required this.revenue,
    required this.profit,
  });

  final int lines;
  final Money? revenue;

  /// Revenue less the lines' cost; null when any sold line's cost is unknown
  /// (hard rule 5), the same rule the category breakdown follows.
  final Money? profit;
}

/// How one dropshipped product has sold.
class DropshipProductPerformance {
  const DropshipProductPerformance({
    required this.itemId,
    required this.title,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
  });

  final String itemId;
  final String title;
  final int unitsSold;
  final Money? revenue;
  final Money? profit;
}

/// How quickly one supplier ships after an order is placed.
class SupplierShipTime {
  const SupplierShipTime({
    required this.sourceId,
    required this.averageDays,
    required this.shipments,
  });

  final String sourceId;
  final double averageDays;
  final int shipments;
}

/// The dropship breakdown (`docs/DROPSHIPPING_PLAN.md`, §6 Analytics): the
/// business split by who ships, products ranked, suppliers timed.
final class DropshipPerformance {
  /// Every revenue-counting line, split into stocked and dropshipped by the
  /// item's fulfilment today.
  static ({FulfilmentFigures stocked, FulfilmentFigures dropship}) split({
    required List<Order> orders,
    required Map<String, Item> items,
  }) {
    final List<OrderLine> stocked = <OrderLine>[];
    final List<OrderLine> dropship = <OrderLine>[];

    for (final OrderLine line in _soldLines(orders)) {
      (items[line.itemId]?.isDropship ?? false ? dropship : stocked).add(line);
    }

    return (stocked: _figures(stocked), dropship: _figures(dropship));
  }

  /// Every dropshipped item, best gross profit first; one with no sale, or
  /// whose profit is unknown, sorts after those with a known figure.
  static List<DropshipProductPerformance> products({
    required List<Order> orders,
    required List<Item> items,
  }) {
    final Map<String, List<OrderLine>> byItem = <String, List<OrderLine>>{};

    for (final OrderLine line in _soldLines(orders)) {
      byItem.putIfAbsent(line.itemId, () => <OrderLine>[]).add(line);
    }

    final List<DropshipProductPerformance> rows = <DropshipProductPerformance>[
      for (final Item item in items)
        if (item.isDropship && !item.isDeleted)
          _product(item, byItem[item.id] ?? const <OrderLine>[]),
    ];

    return rows..sort(_byProfit);
  }

  /// Each supplier's average days from placed to shipped, quickest first.
  static List<SupplierShipTime> shipTimes(List<SupplierOrder> supplierOrders) {
    final Map<String, List<int>> days = <String, List<int>>{};

    for (final SupplierOrder so in supplierOrders) {
      final DateTime? placed = so.placedAt;
      final DateTime? shipped = so.shippedAt;

      if (placed == null || shipped == null) continue;
      days
          .putIfAbsent(so.sourceId, () => <int>[])
          .add(shipped.difference(placed).inDays);
    }

    return <SupplierShipTime>[
      for (final MapEntry<String, List<int>> entry in days.entries)
        SupplierShipTime(
          sourceId: entry.key,
          averageDays:
              entry.value.reduce((int a, int b) => a + b) / entry.value.length,
          shipments: entry.value.length,
        ),
    ]..sort(
      (SupplierShipTime a, SupplierShipTime b) =>
          a.averageDays.compareTo(b.averageDays),
    );
  }

  static Iterable<OrderLine> _soldLines(List<Order> orders) => <OrderLine>[
    for (final Order order in orders)
      if (order.status.countsAsRevenue) ...order.lines,
  ];

  static FulfilmentFigures _figures(List<OrderLine> lines) {
    final Money? revenue = lines
        .map((OrderLine line) => line.lineTotal)
        .totalOfKnown();
    final List<Money?> costs = lines
        .map((OrderLine line) => line.lineCost)
        .toList();
    final Money? cost = costs.allKnown ? costs.totalOfKnown() : null;

    return FulfilmentFigures(
      lines: lines.length,
      revenue: revenue,
      profit: revenue == null || cost == null ? null : revenue - cost,
    );
  }

  static DropshipProductPerformance _product(Item item, List<OrderLine> lines) {
    final FulfilmentFigures figures = _figures(lines);

    return DropshipProductPerformance(
      itemId: item.id,
      title: item.title,
      unitsSold: lines.fold<int>(
        0,
        (int total, OrderLine line) => total + line.quantity,
      ),
      revenue: figures.revenue,
      profit: figures.profit,
    );
  }

  static int _byProfit(
    DropshipProductPerformance a,
    DropshipProductPerformance b,
  ) {
    final Money? left = a.profit;
    final Money? right = b.profit;

    if (left == null && right == null) return b.unitsSold - a.unitsSold;
    if (left == null) return 1;
    if (right == null) return -1;
    if (left.currency != right.currency) return 0;

    return right.compareTo(left);
  }
}

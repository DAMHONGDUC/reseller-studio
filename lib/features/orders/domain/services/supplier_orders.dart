import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../inventory/domain/entities/item.dart';
import '../entities/order.dart';
import '../entities/supplier_order.dart';
import '../enums/order_status.dart';
import '../enums/supplier_order_status.dart';

/// One sold dropship line still waiting to be ordered from its supplier.
class SupplierOrderToPlace {
  const SupplierOrderToPlace({required this.order, required this.line});

  final Order order;
  final OrderLine line;
}

/// Questions about orders placed with suppliers, answered in one place.
final class SupplierOrders {
  /// Sold dropship lines with no live supplier order, oldest sale first.
  ///
  /// A query, not a stored state — the same way stale is one: the moment a
  /// supplier order is recorded, the line leaves this list on its own.
  static List<SupplierOrderToPlace> toPlace({
    required List<Order> orders,
    required Map<String, Item> items,
    required List<SupplierOrder> supplierOrders,
  }) {
    final Set<String> covered = <String>{
      for (final SupplierOrder so in supplierOrders)
        if (so.status != SupplierOrderStatus.cancelled &&
            so.status != SupplierOrderStatus.failed)
          _key(so.orderId, so.itemId),
    };
    final List<SupplierOrderToPlace> pending = <SupplierOrderToPlace>[
      for (final Order order in orders)
        if (order.status == OrderStatus.toShip)
          for (final OrderLine line in order.lines)
            if ((items[line.itemId]?.isDropship ?? false) &&
                !covered.contains(_key(order.id, line.itemId)))
              SupplierOrderToPlace(order: order, line: line),
    ];

    return pending..sort(
      (SupplierOrderToPlace a, SupplierOrderToPlace b) =>
          a.order.orderedAt.compareTo(b.order.orderedAt),
    );
  }

  /// Days a placed order has waited for its tracking number (AutoDS's DAS),
  /// or null once it shipped or when it was never placed.
  static int? daysAwaitingShipment(SupplierOrder order, DateTime now) {
    final DateTime? placed = order.placedAt;

    if (placed == null || order.status != SupplierOrderStatus.placed) {
      return null;
    }

    return DateTimeUtils.daysBetween(placed, now);
  }

  static bool isLate(SupplierOrder order, DateTime now, int afterDays) {
    final int? waiting = daysAwaitingShipment(order, now);

    return waiting != null && waiting > afterDays;
  }

  /// When the buyer should have it: the day it was placed plus the
  /// supplier's delivery days. Null when either is unknown.
  static DateTime? estimatedArrival(SupplierOrder order, int? shippingDays) {
    final DateTime? placed = order.placedAt;

    if (placed == null || shippingDays == null) return null;

    return DateTimeUtils.daysAfter(placed, shippingDays);
  }

  /// What the order cost the seller, net of any supplier refund — the sold
  /// line's cost. Null while the product cost is unknown (hard rule 5).
  static Money? netCost(SupplierOrder order) {
    final Money? product = order.productCost;

    if (product == null || order.status == SupplierOrderStatus.cancelled) {
      return null;
    }

    final String currency = product.currency;
    final List<Money> parts = <Money>[
      product,
      order.shippingCost ?? Money.zero(currency),
      order.tax ?? Money.zero(currency),
    ];

    if (parts.any((Money part) => part.currency != currency)) return null;

    final Money gross = parts.reduce((Money a, Money b) => a + b);
    final Money? refund = order.supplierRefund;

    if (refund == null) return gross;
    if (refund.currency != currency) return null;

    return gross - refund;
  }

  /// [order] with the line for [itemId] costed at [cost].
  static Order withLineCost(Order order, String itemId, Money? cost) =>
      order.copyWith(
        lines: <OrderLine>[
          for (final OrderLine line in order.lines)
            line.itemId == itemId
                ? OrderLine(
                    itemId: line.itemId,
                    title: line.title,
                    quantity: line.quantity,
                    unitPrice: line.unitPrice,
                    unitCost: cost,
                  )
                : line,
        ],
      );

  static String _key(String? orderId, String? itemId) => '$orderId|$itemId';
}

import '../../../../core/money/money.dart';
import '../entities/order.dart';
import '../enums/order_status.dart';

/// The valid moves through an order lifecycle.
final class OrderTransition {
  static Order ship(
    Order order, {
    required DateTime at,
    String? carrier,
    String? trackingNumber,
    Money? shippingCost,
  }) {
    _require(order, <OrderStatus>{OrderStatus.toShip}, 'ship');

    return order.copyWith(
      status: OrderStatus.shipped,
      carrier: carrier,
      trackingNumber: trackingNumber,
      shippingCost: shippingCost,
      shippedAt: at,
    );
  }

  static Order deliver(Order order, {required DateTime at}) {
    _require(order, <OrderStatus>{OrderStatus.shipped}, 'deliver');

    return order.copyWith(status: OrderStatus.delivered, deliveredAt: at);
  }

  static Order requestReturn(Order order, {required DateTime at}) {
    _require(order, <OrderStatus>{
      OrderStatus.shipped,
      OrderStatus.delivered,
    }, 'open return');

    return order.copyWith(
      status: OrderStatus.returnRequested,
      returnRequestedAt: at,
    );
  }

  static Order closeReturn(Order order, {required DateTime at}) {
    _require(order, <OrderStatus>{OrderStatus.returnRequested}, 'close return');

    return order.copyWith(status: OrderStatus.returned, returnedAt: at);
  }

  static Order refund(Order order, Money amount, {required DateTime at}) {
    if (amount.currency != order.salePrice.currency ||
        amount.minor <= 0 ||
        amount > order.salePrice) {
      throw StateError('Invalid refund for order ${order.id}');
    }

    _require(order, <OrderStatus>{
      OrderStatus.toShip,
      OrderStatus.shipped,
      OrderStatus.delivered,
      OrderStatus.returnRequested,
      OrderStatus.returned,
    }, 'refund');

    return order.copyWith(
      status: amount >= order.salePrice ? OrderStatus.refunded : null,
      refund: amount,
      refundedAt: at,
    );
  }

  static Order settle(Order order, {required DateTime at, Money? payout}) {
    _require(order, <OrderStatus>{
      OrderStatus.toShip,
      OrderStatus.shipped,
      OrderStatus.delivered,
      OrderStatus.returnRequested,
      OrderStatus.returned,
      OrderStatus.refunded,
    }, 'settle');

    return order.copyWith(
      payout: payout,
      clearPayout: payout == null,
      settledAt: at,
    );
  }

  static void _require(Order order, Set<OrderStatus> allowed, String action) {
    if (allowed.contains(order.status)) return;

    throw StateError(
      'Cannot $action order ${order.id} from ${order.status.name}',
    );
  }
}

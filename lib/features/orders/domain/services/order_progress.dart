import '../entities/order.dart';
import '../enums/order_stage.dart';
import '../enums/order_status.dart';

/// How far an order has come along `sold → shipped → paid out`.
///
/// **Paid out means the payout is recorded, not that a status says so.** A
/// profit is unknown until the seller writes down what the platform paid
/// (hard rule 3), so the last stage reads `Order.needsPayout` — the same
/// fact Payouts gathers its work from.
///
/// **An order that left the happy path has no track.** A cancelled, refunded
/// or returned order did not stop at a stage; drawing it as "shipped, not
/// yet paid" would promise money that is not coming.
final class OrderProgress {
  /// Null when the order is off the track entirely.
  static Set<OrderStage>? reached(Order order) {
    if (_isOffTrack(order.status)) return null;

    final bool shipped =
        order.shippedAt != null ||
        order.status == OrderStatus.shipped ||
        order.status == OrderStatus.delivered;

    return <OrderStage>{
      OrderStage.sold,
      if (shipped) OrderStage.shipped,
      if (!order.needsPayout) OrderStage.paidOut,
    };
  }

  /// The first stage not reached yet, or null when there is none to reach.
  static OrderStage? next(Order order) {
    final Set<OrderStage>? done = reached(order);

    if (done == null) return null;

    return OrderStage.values
        .where((OrderStage stage) => !done.contains(stage))
        .firstOrNull;
  }

  static bool _isOffTrack(OrderStatus status) => switch (status) {
    OrderStatus.awaitingPayment ||
    OrderStatus.toShip ||
    OrderStatus.shipped ||
    OrderStatus.delivered => false,
    OrderStatus.returnRequested ||
    OrderStatus.returned ||
    OrderStatus.refunded ||
    OrderStatus.cancelled => true,
  };
}

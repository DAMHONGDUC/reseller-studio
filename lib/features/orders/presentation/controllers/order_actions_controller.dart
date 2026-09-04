import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/services/order_transition.dart';

/// Moving an order along: ship it, deliver it, refund it, take it back.
///
/// **The whole `Pick → Pack → Label → Tracking → Shipped → Delivered` flow is
/// one status field and two timestamps** (plan §8). Modelling each step as its
/// own state would give a seller five taps to do what they experience as one
/// action — putting a parcel in a bag and handing it over.
///
/// Shipping information is required *at* the transition, not before (plan
/// §29): an order can sit in "to ship" with no carrier, and the carrier is
/// asked for when it actually goes.
class OrderActionsController extends Notifier<bool> {
  /// True while a write is in flight.
  @override
  bool build() => false;

  /// Mark an order shipped, with whatever the seller knows about the parcel.
  ///
  /// Everything except the order is optional: a seller who dropped it at the
  /// post office with no tracking still needs the order to leave their queue,
  /// and blocking that would make the queue lie.
  Future<void> markShipped(
    Order order, {
    String? carrier,
    String? trackingNumber,
    Money? shippingCost,
    DateTime? shippedAt,
  }) {
    AppAnalytics.instance.orderShipped(hasTracking: trackingNumber != null);

    return _save(
      'Ship order',
      OrderTransition.ship(
        order,
        at: shippedAt ?? DateTime.now(),
        carrier: carrier,
        trackingNumber: trackingNumber,
        shippingCost: shippingCost,
      ),
      <String, Object>{
        'hasTracking': trackingNumber != null,
        'hasCarrier': carrier != null,
      },
    );
  }

  /// Mark a whole post-office run shipped, with one carrier for all of it.
  ///
  /// **No tracking number, and that is the point.** A tracking number belongs
  /// to one parcel, so asking for one here would put the seller back into
  /// twelve sheets — which is the thing this replaces. The carrier is the
  /// half that really is the same for the run, and anything per-parcel is
  /// added afterwards on the order itself.
  ///
  /// Sequential rather than a `Future.wait`: a mid-run failure must leave the
  /// orders before it shipped and the queue honest about the rest.
  Future<void> markManyShipped(List<Order> orders, {String? carrier}) async {
    SdLogger.action(LogTagConstant.order, 'Ship orders', <String, Object>{
      'count': orders.length,
      'hasCarrier': carrier != null,
    });

    for (final Order order in orders) {
      await markShipped(order, carrier: carrier);
    }
  }

  Future<void> markDelivered(Order order) => _save(
    'Deliver order',
    OrderTransition.deliver(order, at: DateTime.now()),
    const <String, Object>{},
  );

  /// Record what the marketplace actually paid out.
  ///
  /// **The one stored figure that is not derived** (hard rule 3): it is a fact
  /// the platform reported, and it is what the seller reconciles their bank
  /// against.
  Future<void> recordSettlement(Order order, {Money? fees, Money? payout}) =>
      _save(
        'Record settlement',
        OrderTransition.settle(
          order,
          at: DateTime.now(),
          fees: fees,
          payout: payout,
        ),
        <String, Object>{'hasFees': fees != null, 'hasPayout': payout != null},
      );

  Future<void> requestReturn(Order order) {
    AppAnalytics.instance.returnOpened();

    return _save(
      'Open return',
      OrderTransition.requestReturn(order, at: DateTime.now()),
      const <String, Object>{},
    );
  }

  /// The item is physically back.
  ///
  /// [restock] puts it back on the shelf. Optional because a return often
  /// comes back damaged, and silently restocking a broken item would have the
  /// seller sell it twice.
  Future<void> markReturned(Order order, {required bool restock}) async {
    final Order returned = OrderTransition.closeReturn(
      order,
      at: DateTime.now(),
    );

    SdLogger.action(LogTagConstant.order, 'Close return', <String, Object>{
      'orderId': order.id,
      'restock': restock,
    });
    state = true;

    try {
      await ref
          .read(orderRepositoryProvider)
          .closeReturn(returned, restock: restock);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Failed to close return',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'orderId': order.id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Money back to the buyer, in part or in full (plan §16).
  ///
  /// **Only a full refund changes the status.** A goodwill £10 off a £100
  /// order that the buyer kept is still a sale: flipping it to `refunded`
  /// would make `countsAsRevenue` false and erase the whole £100 from every
  /// figure, when what actually happened is that £90 was earned. A partial
  /// refund is carried by `Order.refund`, which every revenue line already
  /// subtracts.
  Future<void> refund(Order order, Money amount) {
    final bool isFull = amount == order.salePrice;

    return _save(
      'Refund order',
      OrderTransition.refund(order, amount, at: DateTime.now()),
      <String, Object>{'refundMinor': amount.minor, 'isFull': isFull},
    );
  }

  Future<void> cancel(Order order) => _save(
    'Cancel order',
    order.copyWith(status: OrderStatus.cancelled),
    const <String, Object>{},
  );

  /// The one write path, so every transition logs the same way.
  Future<void> _save(
    String describe,
    Order order,
    Map<String, Object> data,
  ) async {
    SdLogger.action(LogTagConstant.order, describe, <String, Object>{
      'orderId': order.id,
      'status': order.status.name,
      ...data,
    });

    state = true;

    try {
      await ref.read(orderRepositoryProvider).save(order);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Failed to $describe',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'orderId': order.id, ...data},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<OrderActionsController, bool>
orderActionsControllerProvider = NotifierProvider<OrderActionsController, bool>(
  OrderActionsController.new,
);

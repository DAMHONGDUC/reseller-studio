import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/enums/item_status.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';

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
      order.copyWith(
        status: OrderStatus.shipped,
        carrier: carrier,
        trackingNumber: trackingNumber,
        shippingCost: shippingCost,
        shippedAt: shippedAt ?? DateTime.now(),
      ),
      <String, Object>{
        'hasTracking': trackingNumber != null,
        'hasCarrier': carrier != null,
      },
    );
  }

  Future<void> markDelivered(Order order) => _save(
    'Deliver order',
    order.copyWith(status: OrderStatus.delivered, deliveredAt: DateTime.now()),
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
        order.copyWith(fees: fees, payout: payout),
        <String, Object>{'hasFees': fees != null, 'hasPayout': payout != null},
      );

  Future<void> requestReturn(Order order) {
    AppAnalytics.instance.returnOpened();

    return _save(
      'Open return',
      order.copyWith(status: OrderStatus.returnRequested),
      const <String, Object>{},
    );
  }

  /// The item is physically back.
  ///
  /// [restock] puts it back on the shelf. Optional because a return often
  /// comes back damaged, and silently restocking a broken item would have the
  /// seller sell it twice.
  Future<void> markReturned(Order order, {required bool restock}) async {
    await _save(
      'Close return',
      order.copyWith(status: OrderStatus.returned),
      <String, Object>{'restock': restock},
    );

    if (!restock) return;

    final ItemRepository items = ref.read(itemRepositoryProvider);

    try {
      final List<Item> restocked = <Item>[];

      for (final OrderLine line in order.lines) {
        final Item? item = await items.findById(line.itemId);

        if (item == null) continue;

        restocked.add(item.copyWith(status: ItemStatus.inStock));
      }

      await items.saveAll(restocked);

      AppLogger.info('Returned items restocked', <String, Object>{
        'orderId': order.id,
        'count': restocked.length,
      });
    } catch (error, stackTrace) {
      // The order is already back; failing to restock is a second, smaller
      // problem and must not report the whole return as failed.
      AppLogger.error(
        'Failed to restock returned items',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'orderId': order.id},
      );

      rethrow;
    }
  }

  /// Money back to the buyer, in part or in full.
  Future<void> refund(Order order, Money amount) => _save(
    'Refund order',
    order.copyWith(status: OrderStatus.refunded, refund: amount),
    <String, Object>{'refundMinor': amount.minor},
  );

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
    AppLogger.action(describe, <String, Object>{
      'orderId': order.id,
      'status': order.status.name,
      ...data,
    });

    state = true;

    try {
      await ref.read(orderRepositoryProvider).save(order);
    } catch (error, stackTrace) {
      AppLogger.error(
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

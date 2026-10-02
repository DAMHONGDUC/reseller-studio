import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_stage.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/order_progress.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// `sold → shipped → paid out`, read off facts already on the order.
void main() {
  late Order base;

  setUpAll(() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    // Not shipped and not paid out, so each case below adds only the facts
    // it is about — `copyWith` cannot unset a ship date.
    base = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order order) => order.shippedAt == null)
        .copyWith(clearPayout: true);
  });

  Order shaped({
    required OrderStatus status,
    DateTime? shippedAt,
    bool payout = false,
  }) => base.copyWith(
    status: status,
    shippedAt: shippedAt,
    payout: payout ? base.salePrice : null,
  );

  test('a sale waiting to ship has only been sold', () {
    final Order order = shaped(status: OrderStatus.toShip);

    expect(OrderProgress.reached(order), <OrderStage>{OrderStage.sold});
    expect(OrderProgress.next(order), OrderStage.shipped);
  });

  test('shipped with no payout waits on the payout, not on a status', () {
    final Order order = shaped(
      status: OrderStatus.delivered,
      shippedAt: DateTime(2026, 8),
    );

    expect(OrderProgress.reached(order), <OrderStage>{
      OrderStage.sold,
      OrderStage.shipped,
    });
    expect(OrderProgress.next(order), OrderStage.paidOut);
  });

  test('a payout recorded before shipping still ticks paid out', () {
    // The payout box is on the mark-sold sheet, so this happens.
    final Order order = shaped(status: OrderStatus.toShip, payout: true);

    expect(OrderProgress.reached(order), contains(OrderStage.paidOut));
    expect(OrderProgress.next(order), OrderStage.shipped);
  });

  test('every stage reached leaves nothing next', () {
    final Order order = shaped(
      status: OrderStatus.delivered,
      shippedAt: DateTime(2026, 8),
      payout: true,
    );

    expect(OrderProgress.reached(order), OrderStage.values.toSet());
    expect(OrderProgress.next(order), isNull);
  });

  test('an order off the happy path has no track at all', () {
    for (final OrderStatus status in <OrderStatus>[
      OrderStatus.cancelled,
      OrderStatus.refunded,
      OrderStatus.returned,
      OrderStatus.returnRequested,
    ]) {
      final Order order = shaped(status: status);

      expect(OrderProgress.reached(order), isNull, reason: status.name);
      expect(OrderProgress.next(order), isNull, reason: status.name);
    }
  });
}

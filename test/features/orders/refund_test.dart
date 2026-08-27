import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/order_actions_controller.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// A partial refund is the case this is written for: treating one as a full
/// refund flips `countsAsRevenue` and erases the whole sale from every figure.
void main() {
  Future<Order> refunded(
    ProviderContainer container,
    Order order,
    int minor,
  ) async {
    await container
        .read(orderActionsControllerProvider.notifier)
        .refund(order, Money(minor, order.salePrice.currency));

    await warmUp(container);

    return container
        .read(ordersProvider)
        .value!
        .firstWhere((Order saved) => saved.id == order.id);
  }

  Future<Order> anyDelivered(ProviderContainer container) async {
    await warmUp(container);

    return container.read(ordersProvider).value!.firstWhere(
      (Order order) => order.status == OrderStatus.delivered,
    );
  }

  test('a partial refund leaves the order counting as revenue', () async {
    final ProviderContainer container = mockContainer();
    final Order order = await anyDelivered(container);
    final Order after = await refunded(container, order, 1000);

    expect(after.status, OrderStatus.delivered);
    expect(after.refund!.minor, 1000);
    expect(after.status.countsAsRevenue, isTrue);
  });

  test('a refund of the whole sale marks it refunded', () async {
    final ProviderContainer container = mockContainer();
    final Order order = await anyDelivered(container);
    final Order after = await refunded(container, order, order.salePrice.minor);

    expect(after.status, OrderStatus.refunded);
    expect(after.status.countsAsRevenue, isFalse);
  });

  test('the refund comes off the profit rather than the sale price', () async {
    final ProviderContainer container = mockContainer();
    final Order order = await anyDelivered(container);
    final Order after = await refunded(container, order, 1000);

    // The sale price is what the buyer paid and stays history; the refund is
    // what came back out of it.
    expect(after.salePrice, order.salePrice);
    expect(
      after.profit().revenue.minor,
      order.salePrice.minor - 1000,
    );
  });
}

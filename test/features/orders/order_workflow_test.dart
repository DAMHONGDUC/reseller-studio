import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/order_actions_controller.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

void main() {
  Future<void> ready(ProviderContainer container) => warmUp(container);

  test('Shipping Queue contains to-ship orders and no returns', () async {
    final ProviderContainer container = mockContainer();
    await ready(container);

    final List<Order> queue = container.read(ordersNeedingActionProvider);

    expect(queue, isNotEmpty);
    expect(
      queue.every((Order order) => order.status == OrderStatus.toShip),
      isTrue,
    );
    expect(queue.any((Order order) => order.id == 'ord-6'), isFalse);
  });

  test('closing a return restores its quantity in the same workflow', () async {
    final ProviderContainer container = mockContainer();
    await ready(container);

    final Order order = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order value) => value.id == 'ord-6');
    final Item before = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item value) => value.id == 'itm-11');

    await container
        .read(orderActionsControllerProvider.notifier)
        .markReturned(order, restock: true);

    final Order returned = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order value) => value.id == 'ord-6');
    final Item after = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item value) => value.id == 'itm-11');

    expect(returned.status, OrderStatus.returned);
    expect(after.quantity, before.quantity + order.lines.single.quantity);
  });

  test('a returned order keeps revenue until a refund is recorded', () {
    expect(OrderStatus.returned.countsAsRevenue, isTrue);
  });

  test('only an order waiting to ship can become overdue', () {
    final DateTime now = DateTime(2026, 8, 29);
    final Order toShip = Order(
      id: 'to-ship',
      status: OrderStatus.toShip,
      lines: const <OrderLine>[],
      salePrice: Money(1000, 'USD'),
      orderedAt: now,
      shipByDate: now.subtract(const Duration(days: 1)),
    );
    final Order returning = toShip.copyWith(
      status: OrderStatus.returnRequested,
    );

    expect(toShip.isOverdue(now), isTrue);
    expect(returning.isOverdue(now), isNull);
  });

  test('custom marketplace identity survives recording a sale', () async {
    final ProviderContainer container = mockContainer();
    await ready(container);
    final Item item = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item value) => value.id == 'itm-8');

    final String id = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[item],
          salePrice: Money(12000, 'USD'),
          marketplaceId: 'sunday-market',
          marketplaceName: 'Sunday Market',
          soldAt: testNow,
        );
    final Order order = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order value) => value.id == id);

    expect(order.marketplaceId, 'sunday-market');
    expect(order.marketplaceName, 'Sunday Market');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/order_transition.dart';

void main() {
  final DateTime now = DateTime(2026, 8, 29);

  Order order(OrderStatus status) => Order(
    id: 'order-1',
    status: status,
    marketplaceRecordId: 'ebay',
    marketplaceNameSnapshot: 'eBay',
    lines: const <OrderLine>[],
    salePrice: Money(10000, 'USD'),
    orderedAt: now,
  );

  test('only a paid to-ship order can be shipped', () {
    expect(
      () => OrderTransition.ship(order(OrderStatus.awaitingPayment), at: now),
      throwsStateError,
    );
    expect(
      OrderTransition.ship(order(OrderStatus.toShip), at: now).status,
      OrderStatus.shipped,
    );
  });

  test('returns follow shipped to requested to returned', () {
    final Order requested = OrderTransition.requestReturn(
      order(OrderStatus.shipped),
      at: now,
    );
    final Order returned = OrderTransition.closeReturn(requested, at: now);

    expect(requested.returnRequestedAt, now);
    expect(returned.status, OrderStatus.returned);
    expect(returned.returnedAt, now);
  });

  test('a refund must be positive and cannot exceed the sale', () {
    expect(
      () => OrderTransition.refund(
        order(OrderStatus.delivered),
        Money(10001, 'USD'),
        at: now,
      ),
      throwsStateError,
    );
    expect(
      OrderTransition.refund(
        order(OrderStatus.delivered),
        Money(1000, 'USD'),
        at: now,
      ).status,
      OrderStatus.delivered,
    );
  });
}

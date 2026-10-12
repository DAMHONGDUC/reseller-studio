import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/order_search.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Orders' search finds a sale by whatever the seller has in hand.
void main() {
  final Order order = Order(
    id: 'o1',
    status: OrderStatus.shipped,
    marketplaceRecordId: 'ebay',
    marketplaceNameSnapshot: 'eBay',
    lines: const <OrderLine>[
      OrderLine(
        itemId: 'i1',
        title: 'Levis Trucker Jacket',
        quantity: 1,
        unitPrice: Money(4500, 'USD'),
      ),
    ],
    salePrice: const Money(4500, 'USD'),
    orderedAt: DateTime(2026, 10, 1),
    buyerName: 'Jamie Lee',
    externalOrderId: '12-34567-89012',
    trackingNumber: '9400111899223',
  );

  test('matches the item, buyer, order number, tracking and platform', () {
    for (final String query in <String>[
      'trucker',
      'JAMIE',
      '34567',
      '9400111',
      'ebay',
    ]) {
      expect(OrderSearch.matches(order, query), isTrue, reason: query);
    }
    expect(OrderSearch.matches(order, 'poshmark'), isFalse);
    expect(OrderSearch.matches(order, '  '), isTrue);
  });

  testWidgets('typing in the header narrows the list', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final int before = tester.widgetList(find.byType(SdSwipeRowV3)).length;

    await tester.enterText(
      find.descendant(
        of: find.byType(SdSearchFieldV3),
        matching: find.byType(TextField),
      ),
      'zzz-no-such-order',
    );
    await tester.pumpAndSettle();

    expect(before, greaterThan(0));
    expect(find.byType(SdSwipeRowV3), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/presentation/widgets/ship_order_sheet.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The order card carries `Sold → Shipped → Paid out` and, while the order
/// waits to ship, the one move the list can make on its own.
void main() {
  /// The card holding [title] — titles are unique in the seed.
  Finder cardOf(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(SdCardV3));

  Future<List<Order>> seededOrders(WidgetTester tester) async {
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(OrdersScreen)),
    );

    return container.read(visibleOrdersProvider);
  }

  testWidgets('an order to ship shows the track and a Ship it button', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final Order order = (await seededOrders(
      tester,
    )).firstWhere((Order o) => o.status == OrderStatus.toShip);
    final Finder card = cardOf(order.lines.first.title);

    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).last,
    );

    for (final String stage in <String>['Sold', 'Shipped', 'Paid out']) {
      expect(
        find.descendant(of: card, matching: find.text(stage)),
        findsOneWidget,
        reason: '$stage is missing from the track',
      );
    }

    final Finder ship = find.descendant(
      of: card,
      matching: find.widgetWithText(SdButtonV3, 'Ship it'),
    );

    expect(ship, findsOneWidget);

    await tester.tap(ship);
    await tester.pumpAndSettle();

    // The same sheet the detail screen's pinned button opens.
    expect(find.byType(ShipOrderSheet), findsOneWidget);
  });

  testWidgets('an order that left the happy path has no track', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final List<Order> orders = await seededOrders(tester);
    final Order? off = orders
        .where((Order o) => o.status == OrderStatus.returnRequested)
        .firstOrNull;

    expect(off, isNotNull, reason: 'the seed has an order with a return open');

    final Finder card = cardOf(off!.lines.first.title);

    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).last,
    );

    expect(
      find.descendant(of: card, matching: find.text('Paid out')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('Ship it')),
      findsNothing,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// The two ways this list can be empty are different sentences.
///
/// Orders told a seller with no orders at all that **"No orders match this
/// filter"** — naming a filter they never set, and pointing at a fix that does
/// not exist. Inventory had always told the two apart; this is what stops the
/// screens drifting back apart again.
void main() {
  List<Override> orders(List<Order> rows) => <Override>[
    ordersProvider.overrideWith((Ref ref) => Stream<List<Order>>.value(rows)),
  ];

  testWidgets('no orders at all says so, and never blames a filter', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const OrdersScreen(),
      overrides: orders(const <Order>[]),
    );

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('No orders match this filter.'), findsNothing);
  });

  testWidgets('the way on is offered, because orders start in inventory', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const OrdersScreen(),
      overrides: orders(const <Order>[]),
    );

    expect(find.text('Go to inventory'), findsOneWidget);
  });

  testWidgets('an empty tab on a real business still blames the filter', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    // Shipped is the seeded tab with nothing under it while the others are
    // full — exactly the case the shared widget has to keep telling apart.
    await tester.tap(find.text('Shipped'));
    await tester.pumpAndSettle();

    expect(find.text('No orders match this filter.'), findsOneWidget);
    expect(find.text('No orders yet'), findsNothing);
  });
}

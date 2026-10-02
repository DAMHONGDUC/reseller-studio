import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The two ways this list can be empty are different sentences.
///
/// Orders told a seller with no orders at all that **"No orders match this
/// filter"** — naming a filter they never set, and pointing at a fix that does
/// not exist. Inventory had always told the two apart; this is what stops the
/// screens drifting back apart again.
///
/// The way out of the first empty is now Orders' own create action rather than
/// a detour through Inventory — `lib/features/orders/CLAUDE.md`.
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

  testWidgets('the way on is the screen own create action, in its own words', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const OrdersScreen(),
      overrides: orders(const <Order>[]),
    );

    // Twice: the button in the corner and the empty state's own action say
    // the same thing, so a seller is never taught a second route to it.
    expect(find.text('Record a sale'), findsNWidgets(2));
    expect(find.text('Go to inventory'), findsNothing);
  });

  testWidgets('an empty tab on a real business still blames the filter', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    // Shipped is the seeded tab with nothing under it while the others are
    // full — exactly the case the shared widget has to keep telling apart.
    // The chip, not the order cards' track, which also reads "Shipped".
    await tester.tap(find.widgetWithText(SdFilterChipV3, 'Shipped'));
    await tester.pumpAndSettle();

    expect(find.text('No orders match this filter.'), findsOneWidget);
    expect(find.text('No orders yet'), findsNothing);
  });

  testWidgets('the order ceiling opens the Premium gate before the form', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const OrdersScreen(),
      overrides: <Override>[
        ...orders(const <Order>[]),
        addOrderBlockProvider.overrideWith((Ref ref) => PlanBlock.orderLimit),
      ],
    );

    await tester.tap(find.widgetWithText(SdButtonV3, 'Record a sale'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to continue'), findsOneWidget);
    // The ceiling names its window, because the wall is temporary: the
    // oldest sale drops out of the 30 days and the slot comes back.
    expect(find.textContaining('orders every 30 days'), findsOneWidget);
  });
}

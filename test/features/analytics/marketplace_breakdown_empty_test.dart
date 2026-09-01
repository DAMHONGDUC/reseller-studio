import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **An empty block inside a screen is not an empty screen.** The breakdown
/// sits between two headings in Analytics' list, so the page-owning empty
/// state's band — 32 above, 32 plus the floating bar's footprint below — set
/// its words high in a slot they were supposed to be centred in.
void main() {
  Future<void> pumpWithNoSales(WidgetTester tester) => pumpScreen(
    tester,
    const AnalyticsScreen(),
    overrides: <Override>[
      ordersProvider.overrideWith(
        (Ref ref) => Stream<List<Order>>.value(const <Order>[]),
      ),
    ],
  );

  testWidgets('the empty breakdown keeps the card the rows would have filled', (
    WidgetTester tester,
  ) async {
    await pumpWithNoSales(tester);

    expect(find.text('No sales yet'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('No sales yet'),
        matching: find.byType(SdCardV3),
      ),
      findsOneWidget,
    );
  });

  testWidgets('its words are centred in that card, not pushed to the top', (
    WidgetTester tester,
  ) async {
    await pumpWithNoSales(tester);

    final Finder card = find
        .ancestor(
          of: find.text('No sales yet'),
          matching: find.byType(SdCardV3),
        )
        .first;
    final Rect box = tester.getRect(card);
    final Rect content = tester.getRect(
      find.descendant(of: card, matching: find.byType(Column)).first,
    );

    // Equal air above and below: the card's own padding, and nothing else.
    expect(
      (content.top - box.top - (box.bottom - content.bottom)).abs(),
      lessThan(1),
    );
  });
}

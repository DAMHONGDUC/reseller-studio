import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/carriers/domain/entities/carrier.dart';
import 'package:reseller_studio/features/carriers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/presentation/screens/shipping_queue_screen/shipping_queue_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// A seller with twelve parcels used to open twelve sheets, eleven of which
/// asked the same question. Bulk is a first-class requirement (hard rule 16),
/// and the queue was the last list without it.
void main() {
  /// The scope the pumped screen is actually reading, so a test can tick a
  /// row and then read what the write did.
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(ShippingQueueScreen)),
      );

  /// The order as it stands after the write, read back off the stream.
  Order reread(ProviderContainer container, String orderId) => container
      .read(ordersProvider)
      .value!
      .firstWhere((Order order) => order.id == orderId);

  testWidgets('the bar stays away until parcels are ticked', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ShippingQueueScreen());

    expect(find.text('Mark shipped'), findsNothing);
    // The per-parcel button is the affordance while nothing is selected.
    expect(find.text('Ship'), findsWidgets);
  });

  testWidgets('a long press starts a run and the bar counts it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ShippingQueueScreen());
    await tester.longPress(find.text('Ship').first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Mark shipped'), findsOneWidget);
    // Two ways to ship one row is a mis-tap, so the per-row button goes.
    expect(find.text('Ship'), findsNothing);
  });

  testWidgets('with no carriers on file the run ships without asking', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ShippingQueueScreen());

    final ProviderContainer container = containerOf(tester);
    final Order first = container.read(ordersNeedingActionProvider).first;

    container.read(shippingSelectionProvider.notifier).toggle(first.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark shipped'));
    await tester.pumpAndSettle();

    // A picker with nothing in it would be a dead end between the seller and
    // their queue, and the carrier is optional at the transition anyway.
    final Order shipped = reread(container, first.id);

    expect(shipped.status, OrderStatus.shipped);
    expect(shipped.carrier, isNull);
    expect(container.read(shippingSelectionProvider), isEmpty);
  });

  testWidgets('with carriers on file it asks once, then ships the run', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const ShippingQueueScreen(),
      overrides: <Override>[
        activeCarriersProvider.overrideWithValue(<Carrier>[
          Carrier(id: 'usps', name: 'USPS', createdAt: testNow),
          Carrier(id: 'ups', name: 'UPS', createdAt: testNow),
        ]),
      ],
    );

    final ProviderContainer container = containerOf(tester);
    final Order first = container.read(ordersNeedingActionProvider).first;

    container.read(shippingSelectionProvider.notifier).toggle(first.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark shipped'));
    await tester.pumpAndSettle();

    expect(find.text('USPS'), findsOneWidget);

    await tester.tap(find.text('USPS'));
    await tester.pumpAndSettle();

    final Order shipped = reread(container, first.id);

    expect(shipped.status, OrderStatus.shipped);
    expect(shipped.carrier, 'USPS');
    expect(container.read(shippingSelectionProvider), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/mark_sold_sheet.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/record_sale_screen/record_sale_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// One payment for several things is one order.
///
/// Poshmark bundles and Depop's "2 for £15" are everyday. Splitting one into
/// several orders with invented prices destroys the per-item ROI that Sourcing
/// exists to measure, and `OrderLine.itemId` stays non-null so there is still
/// no walk-in sale.
void main() {
  List<Item> sellable(ProviderContainer container) =>
      container.read(sellableItemsProvider);

  test('a bundle is one order with a line per item', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final List<Item> items = sellable(container).take(2).toList();
    final int before = container.read(ordersProvider).value!.length;

    final String orderId = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          items,
          salePrice: Money(4800, 'USD'),
          marketplace: Marketplace.depop,
          soldAt: testNow,
        );

    await Future<void>.delayed(Duration.zero);

    final List<Order> orders = container.read(ordersProvider).value!;
    final Order written = orders.firstWhere((Order o) => o.id == orderId);

    expect(orders, hasLength(before + 1));
    expect(written.lines, hasLength(2));
    expect(written.salePrice, Money(4800, 'USD'));
  });

  test('the lines add back up to what the buyer paid', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final List<Item> items = sellable(container).take(3).toList();

    final String orderId = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          items,
          salePrice: Money(10000, 'USD'),
          marketplace: Marketplace.other,
          soldAt: testNow,
        );

    await Future<void>.delayed(Duration.zero);

    final Order written = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order o) => o.id == orderId);

    // An order whose lines do not sum to the payment is a reconciliation
    // nobody can close.
    expect(
      written.lines.fold(
        0,
        (int running, OrderLine line) => running + line.lineTotal.minor,
      ),
      10000,
    );
  });

  test('every item in the bundle is decremented, not just the first', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final List<Item> items = sellable(container).take(2).toList();
    final Map<String, int> before = <String, int>{
      for (final Item item in items) item.id: item.quantity,
    };

    await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          items,
          salePrice: Money(4800, 'USD'),
          marketplace: Marketplace.other,
          soldAt: testNow,
        );

    await Future<void>.delayed(Duration.zero);

    final List<Item> after = container.read(itemsProvider).value!;

    // An item with more than one on the shelf stays in stock at a lower
    // count; only the last unit marks it sold. What must never happen is the
    // bundle moving one item and leaving the rest.
    for (final MapEntry<String, int> entry in before.entries) {
      expect(
        after.firstWhere((Item item) => item.id == entry.key).quantity,
        entry.value - 1,
      );
    }
  });

  test('a sale must name at least one item', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    // `OrderLine.itemId` is non-null, so there is still no walk-in sale.
    expect(
      () => container
          .read(recordSaleControllerProvider.notifier)
          .record(
            const <Item>[],
            salePrice: Money(1000, 'USD'),
            marketplace: Marketplace.other,
            soldAt: testNow,
          ),
      throwsStateError,
    );
  });

  testWidgets('long-pressing a row starts a bundle and the bar sells it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const RecordSaleScreen());

    // Nothing is offered until something is ticked: a bundle button over an
    // empty selection would write an order of nothing.
    expect(find.textContaining('as one order'), findsNothing);

    await tester.longPress(
      find.text('Vintage Levi 501 — 34x32, redline selvedge'),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Nike windbreaker — XL'));
    await tester.pumpAndSettle();

    expect(find.text('Sell 2 items as one order'), findsOneWidget);

    await tester.tap(find.text('Sell 2 items as one order'));
    await tester.pumpAndSettle();

    // The same sheet a single sale opens, told it is holding two.
    expect(find.byType(MarkSoldSheet), findsOneWidget);
    expect(find.text('Record a sale of 2 items'), findsOneWidget);
  });
}

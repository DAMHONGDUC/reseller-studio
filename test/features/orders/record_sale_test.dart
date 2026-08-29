import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/record_sale_screen/record_sale_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// The second way an order is created — the Orders tab's own button
/// (`lib/features/orders/CLAUDE.md`).
///
/// What matters here is that it is the *same* sale: one controller writes the
/// order and moves the item, so a sale recorded from Orders cannot produce a
/// half-state that a sale recorded from Inventory does not.
void main() {
  Item itemById(ProviderContainer container, String id) => container
      .read(itemsProvider)
      .value!
      .firstWhere((Item item) => item.id == id);

  test('what can be sold is what is still on the shelf', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final List<Item> sellable = container.read(sellableItemsProvider);

    expect(sellable, isNotEmpty);
    expect(
      sellable.every((Item item) => item.status.isOnHand),
      isTrue,
      reason: 'a sold or archived item cannot be sold again',
    );
    expect(
      sellable.any((Item item) => item.id == 'itm-1'),
      isFalse,
      reason: 'itm-1 is already sold',
    );
    expect(sellable.any((Item item) => item.id == 'itm-4'), isTrue);
  });

  test(
    'recording a sale writes the order and moves the item together',
    () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final Item item = itemById(container, 'itm-8');
      final int ordersBefore = container.read(ordersProvider).value!.length;

      final String orderId = await container
          .read(recordSaleControllerProvider.notifier)
          .record(
            item,
            salePrice: Money(12500, 'USD'),
            marketplace: Marketplace.other,
            soldAt: testNow,
          );

      final List<Order> orders = container.read(ordersProvider).value!;
      final Order written = orders.firstWhere((Order o) => o.id == orderId);

      expect(orders.length, ordersBefore + 1);
      expect(written.salePrice, Money(12500, 'USD'));
      expect(written.lines.single.itemId, item.id);
      // The cost travels onto the line, so the order's profit is derivable
      // without reading the item back (hard rule 3).
      expect(written.lines.single.unitCost, item.purchasePrice);
      expect(itemById(container, 'itm-8').status, ItemStatus.sold);
    },
  );

  test(
    'an item with no asking price still sells, at what it sold for',
    () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      // A draft from Quick Add: a title and nothing else (hard rule 2).
      final Item draft = itemById(container, 'itm-9');

      expect(draft.askingPrice, isNull, reason: 'the seed item drifted');

      await container
          .read(recordSaleControllerProvider.notifier)
          .record(
            draft,
            salePrice: Money(4000, 'USD'),
            marketplace: Marketplace.ebay,
            soldAt: testNow,
          );

      final Item sold = itemById(container, 'itm-9');

      expect(sold.status, ItemStatus.sold);
      expect(sold.askingPrice, Money(4000, 'USD'));
    },
  );

  testWidgets('Orders offers the sale as its create action', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    expect(find.text('Record a sale'), findsOneWidget);
  });

  testWidgets('the picker lists the shelf and nothing that has left it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const RecordSaleScreen());

    expect(
      find.text('Vintage Levi 501 — 34x32, redline selvedge'),
      findsOneWidget,
    );
    expect(
      find.text('Patagonia Synchilla fleece — mens L'),
      findsNothing,
      reason: 'already sold, so it cannot be sold again',
    );
  });

  testWidgets('the search box narrows the shelf by SKU', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const RecordSaleScreen());

    await tester.enterText(find.byType(TextField).first, 'AF-0021');
    await tester.pumpAndSettle();

    expect(find.text('Le Creuset dutch oven — 5.5qt, flame'), findsOneWidget);
    expect(
      find.text('Vintage Levi 501 — 34x32, redline selvedge'),
      findsNothing,
    );
  });

  testWidgets('an empty shelf sends the seller to inventory, not to a form', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const RecordSaleScreen(),
      overrides: <Override>[
        itemsProvider.overrideWith(
          (Ref ref) => Stream<List<Item>>.value(const <Item>[]),
        ),
      ],
    );

    expect(find.text('Nothing on the shelf'), findsOneWidget);
    expect(find.text('Go to inventory'), findsOneWidget);
  });
}

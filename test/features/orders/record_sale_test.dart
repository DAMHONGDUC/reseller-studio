import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/core/widgets/money_field.dart';
import 'package:reseller_studio/core/widgets/option_picker_sheet.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart'
    as record;
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/record_sale_screen/record_sale_screen.dart';
import 'package:reseller_studio/features/orders/presentation/widgets/cannot_sell_sheet.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/add_button_finder.dart';
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
            <Item>[item],
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

  test('an item with no price anywhere still sells', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    // A draft from Quick Add: a title and nothing else (hard rule 2).
    final Item draft = itemById(container, 'itm-9');

    expect(draft.purchasePrice, isNull, reason: 'the seed item drifted');

    await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[draft],
          salePrice: Money(4000, 'USD'),
          marketplace: Marketplace.ebay,
          soldAt: testNow,
        );

    final Item sold = itemById(container, 'itm-9');

    // The sale price rides on the order, never back onto the item: the
    // item has no price of its own to write it to.
    expect(sold.status, ItemStatus.sold);
  });

  testWidgets('Orders offers the sale as its create action', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    expect(AddButtonFinder.named('Record a sale'), findsOneWidget);
  });

  testWidgets('the picker lists what has left the shelf too, with its reason', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const RecordSaleScreen());

    expect(
      await revealText(tester, 'Vintage Levi 501 — 34x32, redline selvedge'),
      findsOneWidget,
    );
    // **Shown, not hidden** — owner's rule. Filtering the row out said the
    // item does not exist, where the truth is that it cannot be sold again.
    final Finder sold = await revealText(
      tester,
      'Patagonia Synchilla fleece — mens L',
    );

    expect(sold, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: sold, matching: find.byType(ItemCard)),
        matching: find.text('Cannot sell'),
      ),
      findsOneWidget,
      reason: 'the row flags it as a tag; the reason in full is a tap away',
    );
  });

  testWidgets('tapping a row that cannot be sold explains instead of nothing', (
    WidgetTester tester,
  ) async {
    // **The card is never drawn dead** — owner's rule. A greyed row says the
    // seller did something wrong and offers nothing; the tap is what turns the
    // refusal into an explanation with somewhere to go.
    await pumpScreen(tester, const RecordSaleScreen());

    await tester.tap(
      await revealText(tester, 'Patagonia Synchilla fleece — mens L'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CannotSellSheet), findsOneWidget);
    expect(find.text('This item has already left inventory'), findsOneWidget);
    expect(find.text('Open item'), findsOneWidget);
    // The sale sheet is what a sellable row opens, and this row is not one.
    expect(find.text('Sold on'), findsNothing);
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

  testWidgets('a row carries where it is listed and what it is expected to '
      'fetch, never a listing price', (WidgetTester tester) async {
    // Owner's rule: the price on this row was the highest of several and the
    // seller was about to be asked to confirm it anyway. What decides which
    // row to tap is where the thing is live and what they wanted for it. The
    // card is Inventory's own — a second owner's rule — so both facts arrive
    // as the badge and the money band it already draws.
    await pumpScreen(tester, const RecordSaleScreen());

    final Finder row = find.ancestor(
      of: await revealText(
        tester,
        'Vintage Levi 501 — 34x32, redline selvedge',
      ),
      matching: find.byType(ItemCard),
    );

    // itm-4 is on eBay and Depop, and is expected to fetch 180.
    expect(
      find.descendant(of: row, matching: find.textContaining('2 markets')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text(r'$180.00')),
      findsOneWidget,
    );
  });

  testWidgets('an item on no marketplace says so on its row', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const RecordSaleScreen());

    final Finder row = find.ancestor(
      of: await revealText(tester, 'Nike windbreaker — XL'),
      matching: find.byType(ItemCard),
    );

    expect(
      find.descendant(of: row, matching: find.textContaining('Not listed')),
      findsOneWidget,
    );
    // Nobody entered an expected price for it — a dash, never a zero
    // (hard rule 5). The band carries a cell per figure, so more than one of
    // them can be a dash on an item nobody has costed either.
    expect(find.descendant(of: row, matching: find.text('—')), findsWidgets);
  });

  group('the sale offers only the marketplaces the item is on', () {
    Future<void> openMarketplacePicker(
      WidgetTester tester,
      String title,
    ) async {
      await pumpScreen(tester, const RecordSaleScreen());
      await tester.tap(await revealText(tester, title));
      await tester.pumpAndSettle();

      // The sheet's marketplace box, opened onto the picker beneath it.
      await tester.tap(find.text('Sold on'));
      await tester.pumpAndSettle();
    }

    testWidgets('a listed item offers those platforms and no others', (
      WidgetTester tester,
    ) async {
      // Owner's rule: picking a platform the item was never on writes an
      // order against a marketplace that never carried it.
      await openMarketplacePicker(
        tester,
        'Vintage Levi 501 — 34x32, redline selvedge',
      );

      final Finder picker = find.byType(OptionPickerSheet<record.Marketplace>);

      expect(
        find.descendant(of: picker, matching: find.text('eBay')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: picker, matching: find.text('Depop')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: picker, matching: find.text('Etsy')),
        findsNothing,
      );
      expect(
        find.descendant(of: picker, matching: find.text('Vinted')),
        findsNothing,
      );
    });

    testWidgets('an item on nothing still offers every marketplace', (
      WidgetTester tester,
    ) async {
      // Cash in hand is a sale: an empty picker would be a flow with no way
      // out for stock that was never listed.
      await openMarketplacePicker(tester, 'Nike windbreaker — XL');

      final Finder picker = find.byType(OptionPickerSheet<record.Marketplace>);

      for (final String name in <String>['eBay', 'Etsy', 'Vinted']) {
        expect(
          find.descendant(of: picker, matching: find.text(name)),
          findsOneWidget,
        );
      }
    });
  });

  testWidgets('the sheet opens on what the first platform is asking', (
    WidgetTester tester,
  ) async {
    // Owner's rule: itm-4 is live at 185 on eBay, and 180 is what the item
    // expects. The box seeded from the expected price until the sheet learned
    // to wait for the listings — so the seller had to re-pick the marketplace
    // they were already on to see the right number.
    await pumpScreen(tester, const RecordSaleScreen());
    await tester.tap(
      await revealText(tester, 'Vintage Levi 501 — 34x32, redline selvedge'),
    );
    await tester.pumpAndSettle();

    expect(find.text('eBay'), findsOneWidget, reason: 'the sheet opens on it');
    expect(
      tester
          .widget<MoneyField>(find.widgetWithText(MoneyField, 'Sale price'))
          .controller
          .text,
      '185.00',
    );
  });

  testWidgets('picking a marketplace fills the sale price with what that '
      'platform is asking', (WidgetTester tester) async {
    // Owner's rule: itm-4 is live at 185 on eBay and 175 on Depop, so the box
    // follows the picker rather than holding one of the two.
    await pumpScreen(tester, const RecordSaleScreen());
    await tester.tap(
      await revealText(tester, 'Vintage Levi 501 — 34x32, redline selvedge'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sold on'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(OptionPickerSheet<record.Marketplace>),
        matching: find.text('Depop'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.descendant(
              // By label: the sheet also carries a platform-fee box, and an
              // unscoped MoneyField finder would match both.
              of: find.widgetWithText(MoneyField, 'Sale price'),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      '175.00',
    );
  });

  testWidgets('a marketplace the item is not on falls back to the expected '
      'price', (WidgetTester tester) async {
    // itm-11 is listed nowhere, so every platform is offered and none of them
    // has a price of its own.
    await pumpScreen(tester, const RecordSaleScreen());
    await tester.tap(await revealText(tester, 'Nike windbreaker — XL'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sold on'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(OptionPickerSheet<record.Marketplace>),
        matching: find.text('Etsy'),
      ),
    );
    await tester.pumpAndSettle();

    // Nobody entered an expected price for it either, so the box is empty
    // rather than showing a number belonging to another platform.
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              // By label: the sheet also carries a platform-fee box, and an
              // unscoped MoneyField finder would match both.
              of: find.widgetWithText(MoneyField, 'Sale price'),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      isEmpty,
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

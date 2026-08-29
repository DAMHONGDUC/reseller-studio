import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// What the row says about money and about time.
///
/// The figures are the reason the card is worth its height: an inventory list
/// a seller cannot judge from is a list they open forty times.
void main() {
  Item itemWith({
    Money? cost,
    Money? asking,
    ItemStatus status = ItemStatus.inStock,
  }) => Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: status,
    createdAt: testNow.subtract(const Duration(days: 40)),
    listedAt: testNow.subtract(const Duration(days: 21)),
    purchasePrice: cost,
    askingPrice: asking,
  );

  testWidgets('the band leads with how many are left', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
      ),
    );

    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a sold item has none left, and says so as a zero', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(status: ItemStatus.sold),
        now: testNow,
      ),
    );

    // A known zero, not a missing figure: the em dashes beside it are the
    // amounts nobody entered.
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the band states cost, and neither asking price nor profit', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(
          cost: const Money(4500, 'USD'),
          asking: const Money(18500, 'USD'),
        ),
        now: testNow,
      ),
    );

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text(r'$45.00'), findsOneWidget);
    // What the item is asked for is a per-marketplace number, and the arrow
    // is what leads to them. Expected profit is the detail screen's.
    expect(find.text('Asking'), findsNothing);
    expect(find.text(r'$185.00'), findsNothing);
    expect(find.text('Profit'), findsNothing);
    expect(find.text(r'$140.00'), findsNothing);
  });

  testWidgets('the band spaces its cells apart, edge to edge', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        onMarketPrices: () {},
      ),
    );

    // The divider spans the card's content width, so it is what the band's
    // two ends have to reach. The arrow overhangs the card's padding by
    // design, so it is the glyph rather than its target that lines up.
    final Rect band = tester.getRect(find.byType(SdDividerV3));

    expect(tester.getRect(find.text('Qty')).left, moreOrLessEquals(band.left));
    expect(
      tester
          .getRect(
            find.descendant(
              of: find.byTooltip('Prices on each marketplace'),
              matching: find.byType(SdIconV3),
            ),
          )
          .right,
      moreOrLessEquals(band.right, epsilon: 0.5),
    );
  });

  testWidgets('the arrow opens the marketplace prices', (
    WidgetTester tester,
  ) async {
    int taps = 0;

    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        onMarketPrices: () => taps++,
      ),
    );

    await tester.tap(find.byTooltip('Prices on each marketplace'));

    expect(taps, 1);
  });

  testWidgets('an item that has left inventory keeps the slot, not the arrow', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(status: ItemStatus.sold),
        now: testNow,
        onMarketPrices: () {},
      ),
    );

    // The cross-list screen refuses a sold item, so the row must not offer a
    // way in — but the space stays, or Qty and Cost move on that row alone.
    expect(find.byTooltip('Prices on each marketplace'), findsNothing);
  });

  testWidgets('a Quick Add row says the figures are missing, never zero', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(status: ItemStatus.draft),
        now: testNow,
      ),
    );

    // Hard rule 5: the cost renders an em dash rather than a zero, which
    // would tell the seller the item was free.
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('the row does not show state age', (WidgetTester tester) async {
    await pumpScreen(tester, ItemCard(item: itemWith(), now: testNow));

    expect(find.text('3w'), findsNothing);
    expect(find.widgetWithText(SdBadgeV3, 'In stock'), findsOneWidget);
  });
}

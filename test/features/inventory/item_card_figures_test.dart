import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/app_photo.dart';
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

  testWidgets('the actions target keeps equal horizontal card padding', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(item: itemWith(), now: testNow, onActions: () {}),
    );

    final Rect card = tester.getRect(find.byType(SdCardV3));
    final Rect thumbnail = tester.getRect(find.byType(AppPhoto));
    final Rect actionsTarget = tester.getRect(
      find.descendant(
        of: find.byTooltip('Actions'),
        matching: find.byType(InkResponse),
      ),
    );

    expect(
      thumbnail.left - card.left,
      moreOrLessEquals(card.right - actionsTarget.right),
    );
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
    expect(find.text('Price'), findsNothing);
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
    // two ends have to reach.
    final Rect band = tester.getRect(find.byType(SdDividerV3));

    expect(tester.getRect(find.text('Qty')).left, moreOrLessEquals(band.left));
    expect(
      tester.getRect(find.text('Price')).right,
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

    expect(find.text('Price'), findsOneWidget);

    // The label is part of the target, not decoration above an icon-only
    // button.
    await tester.tap(find.text('Price'));

    expect(taps, 1);
  });

  testWidgets('the Price target is circular and uses the Cost content gap', (
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

    final Finder priceTarget = find.ancestor(
      of: find.text('Price'),
      matching: find.byType(InkResponse),
    );
    final InkResponse ink = tester.widget<InkResponse>(priceTarget);
    final Finder arrow = find.descendant(
      of: priceTarget,
      matching: find.byType(SdIconV3),
    );

    expect(ink.highlightShape, BoxShape.circle);
    expect(ink.customBorder, isA<CircleBorder>());
    expect(tester.getSize(priceTarget), Size.square(SdSpacingConstant.r44));
    expect(
      tester.getCenter(find.text('Price')).dx,
      moreOrLessEquals(tester.getCenter(priceTarget).dx),
    );
    expect(
      tester.getCenter(arrow).dx,
      moreOrLessEquals(tester.getCenter(priceTarget).dx),
    );
    expect(
      tester.getRect(arrow).top - tester.getRect(find.text('Price')).bottom,
      moreOrLessEquals(SdSpacingConstant.h2),
    );
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
    expect(find.text('Price'), findsOneWidget);
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

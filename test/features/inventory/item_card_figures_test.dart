import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/app_photo.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// What the row says about money and about time.
///
/// The figures are the reason the card is worth its height: an inventory list
/// a seller cannot judge from is a list they open forty times.
void main() {
  Item itemWith({
    Money? cost,
    Money? expected,
    ItemStatus status = ItemStatus.inStock,
  }) => Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: status,
    createdAt: testNow.subtract(const Duration(days: 40)),
    listedAt: testNow.subtract(const Duration(days: 21)),
    purchasePrice: cost,
    expectedPrice: expected,
  );

  testWidgets('the band leads with how many are left', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
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
      ItemCard(
        item: itemWith(),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
        onActions: () {},
      ),
    );

    final Rect card = tester.getRect(find.byType(SdCardV3));
    final Rect thumbnail = tester.getRect(find.byType(AppPhoto));
    // The glyph keeps the padding, not the target: the 44pt `InkResponse`
    // overhangs into the card's own inset so the dots hold the content edge
    // rather than sitting 12 points inside every chevron in the app.
    final Rect dots = tester.getRect(
      find.descendant(
        of: find.byTooltip('Actions'),
        matching: find.byType(Icon),
      ),
    );

    expect(
      thumbnail.left - card.left,
      moreOrLessEquals(card.right - dots.right),
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
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    // A known zero, not a missing figure: the em dashes beside it are the
    // amounts nobody entered.
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the band states neither a marketplace ask nor profit', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(
          cost: const Money(4500, 'USD'),
          expected: const Money(18500, 'USD'),
        ),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text(r'$45.00'), findsOneWidget);
    // What the item is *asked* for is a per-marketplace number, and the arrow
    // is what leads to them. Expected profit is the detail screen's.
    expect(find.text('Asking'), findsNothing);
    expect(find.text('Profit'), findsNothing);
    expect(find.text(r'$140.00'), findsNothing);
  });

  testWidgets('the hairline crosses the card and the band sits inside it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
        onMarketPrices: () {},
      ),
    );

    final Rect rule = tester.getRect(find.byType(SdDividerV3));
    final Rect card = tester.getRect(find.byType(ItemCard));

    // Edge to edge, inside the card's border and nothing else: a hairline
    // that stopped at the content read as a line drawn under one zone rather
    // than as the seam between two.
    expect(rule.left - card.left, lessThanOrEqualTo(SdDividerV3.thickness));
    expect(card.right - rule.right, lessThanOrEqualTo(SdDividerV3.thickness));

    // The band itself still runs from one content edge to the other, so its
    // two ends are the card's inset and not wherever the figures landed.
    expect(
      tester.getRect(find.text('Qty')).left - rule.left,
      moreOrLessEquals(SdSpacingConstant.w16, epsilon: 0.5),
    );
    expect(
      rule.right - tester.getRect(find.text('Price')).right,
      moreOrLessEquals(SdSpacingConstant.w16, epsilon: 0.5),
    );
  });

  testWidgets('the Cost column does not move between two cards', (
    WidgetTester tester,
  ) async {
    // A column of money that shuffles sideways as it scrolls is the one thing
    // this app must not do — the rule `AppListRow.trailingText` states one
    // level down. Cells that all measured themselves under `spaceBetween` put
    // the middle one wherever its own content left it, so `Cost` sat at a
    // different place on every row.
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    final double narrow = tester.getRect(find.text('Cost')).left;

    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(123456, 'USD')),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    expect(tester.getRect(find.text('Cost')).left, moreOrLessEquals(narrow));
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
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
        onMarketPrices: () => taps++,
      ),
    );

    expect(find.text('Price'), findsOneWidget);

    // The label is part of the target, not decoration above an icon-only
    // button.
    await tester.tap(find.text('Price'));

    expect(taps, 1);
  });

  testWidgets('the Price target is circular and costs the band no height', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
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
    // The ink reaches the 44pt target the layout does not reserve: a box that
    // tall made the band taller than the two lines it holds and left dead
    // space under the arrow, while the cells beside it stopped at their text.
    expect(ink.radius, moreOrLessEquals(SdSpacingConstant.r44 / 2));
    expect(
      tester.getRect(priceTarget).bottom,
      moreOrLessEquals(tester.getRect(arrow).bottom, epsilon: 0.5),
    );
    // No wider than the label above the glyph: a square would centre the pair
    // and pull the arrow off the card's right edge, out of the column every
    // other end glyph sits in.
    expect(
      tester.getRect(find.text('Price')).right,
      moreOrLessEquals(tester.getRect(priceTarget).right),
    );
    expect(
      tester.getRect(arrow).right,
      moreOrLessEquals(tester.getRect(priceTarget).right),
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
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
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
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    // Hard rule 5: cost and expected price each render an em dash rather
    // than a zero, which would tell the seller the item was free and that
    // they wanted nothing for it.
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('the band carries the expected price beside the cost', (
    WidgetTester tester,
  ) async {
    // Owner's rule: the one price the item carries itself, true whether it is
    // live on four marketplaces or none. What each of them *asks* stays
    // behind the arrow.
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(
          cost: const Money(2200, 'USD'),
          expected: const Money(9000, 'USD'),
        ),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text(r'$22.00'), findsOneWidget);
    expect(find.text('Expected'), findsOneWidget);
    expect(find.text(r'$90.00'), findsOneWidget);
  });

  testWidgets('the row does not show state age', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(),
        now: testNow,
        staleThreshold: StaleInventoryPolicy.defaultThreshold,
      ),
    );

    expect(find.text('3w'), findsNothing);
    expect(find.widgetWithText(SdBadgeV3, 'In stock'), findsOneWidget);
  });
}

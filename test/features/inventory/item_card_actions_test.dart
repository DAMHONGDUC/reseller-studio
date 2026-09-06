import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_row_chevron.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_actions_sheet.dart';

import '../../support/pump_app.dart';

/// The actions sheet opens from the row — owner's rule.
///
/// Listing, repricing and marking sold are what a seller does while looking at
/// the list. Reaching them only through the detail screen cost a push and a
/// pop per item, which on a forty-row afternoon is eighty taps that buy
/// nothing.
void main() {
  Finder actionsButton() => find.descendant(
    of: find.byType(ItemCard),
    matching: find.byTooltip('Actions'),
  );

  testWidgets('every row offers the actions button', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    expect(actionsButton(), findsWidgets);
  });

  testWidgets('it opens the same sheet the detail screen opens', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    await tester.tap(actionsButton().first);
    await tester.pumpAndSettle();

    expect(find.byType(ItemActionsSheet), findsOneWidget);
  });

  testWidgets('the button does not also open the item', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    await tester.tap(actionsButton().first);
    await tester.pumpAndSettle();

    // The card's own onTap pushes the detail route. If the button let the tap
    // through, the sheet would be sitting on top of a screen the seller never
    // asked for.
    expect(find.byType(InventoryScreen), findsOneWidget);
  });

  testWidgets('the target is a round 44pt one, not a squeezed box', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    // The target is what the `InkResponse` covers, which is no longer what the
    // button occupies in the row: it lays out at the glyph's width so the dots
    // hold the card's content edge, and overflows to the target around them.
    final Size size = tester.getSize(
      find
          .descendant(
            of: actionsButton().first,
            matching: find.byType(InkResponse),
          )
          .first,
    );

    // 44 square, and circular: an icon-only control that ripples as a rounded
    // rectangle acknowledges a tap somewhere other than where it landed.
    expect(size.width, size.height);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(
      tester
          .widget<InkResponse>(
            find
                .descendant(
                  of: actionsButton().first,
                  matching: find.byType(InkResponse),
                )
                .first,
          )
          .customBorder,
      isA<CircleBorder>(),
    );
  });

  testWidgets('the glyph holds the card content edge, not the target box', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final Rect dots = tester.getRect(
      find
          .descendant(of: actionsButton().first, matching: find.byType(Icon))
          .first,
    );
    final Rect arrow = tester.getRect(
      find
          .descendant(
            of: find.byType(ItemCard).first,
            matching: find.byType(AppRowChevron),
          )
          .first,
    );

    // Centring the glyph in a target that stopped at the content edge set it
    // 12 points short of every chevron in the app, and a column of end glyphs
    // out of line reads as a mistake to somebody who cannot say which card is
    // wrong. The overhang is ink over the card's own inset instead.
    expect(dots.right, moreOrLessEquals(arrow.right, epsilon: 0.5));
  });

  testWidgets('it disappears while a bulk selection is open', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    await tester.longPress(find.byType(ItemCard).first);
    await tester.pumpAndSettle();

    // Every tap ticks a row now, and a sheet for one item would lose the rows
    // the seller had just picked.
    expect(actionsButton(), findsNothing);
  });
}

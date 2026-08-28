import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_actions_sheet.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';

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

    final Size size = tester.getSize(
      find
          .descendant(
            of: actionsButton().first,
            matching: find.byType(SizedBox),
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

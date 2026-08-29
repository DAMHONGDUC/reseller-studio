import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_actions_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/restock_sheet.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **Restock adds to the count and brings the row back** — owner's rule.
///
/// Having to un-sell an item by hand before saying more arrived is the step
/// that made sellers create a duplicate item instead, and a duplicate loses
/// the cost history, the listings and the sales the original carries.
void main() {
  Future<void> openActions(WidgetTester tester) async {
    await pumpScreen(tester, const InventoryScreen());
    await tester.tap(
      find
          .descendant(
            of: find.byType(ItemCard),
            matching: find.byTooltip('Actions'),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the actions sheet offers Restock', (WidgetTester tester) async {
    await openActions(tester);

    expect(find.text('Restock'), findsOneWidget);
  });

  testWidgets('a draft is the only row offered Make it in stock', (
    WidgetTester tester,
  ) async {
    await openActions(tester);

    // The list sorts newest-created first and the top row is in stock, so the
    // row must be absent here — offering it would be a verb that does nothing.
    expect(find.text('Make it in stock'), findsNothing);
  });

  test('restocking a sold-out item writes the count and the status', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item sold = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.status == ItemStatus.sold);

    await container.read(itemActionsControllerProvider.notifier).restock(<Item>[
      sold,
    ], 4);
    await Future<void>.delayed(Duration.zero);

    final Item restocked = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.id == sold.id);

    expect(restocked.status, ItemStatus.inStock);
    expect(restocked.quantity, sold.quantity + 4);
    // The sale is undone with it: a row on the shelf carrying a sold date is
    // one every export reads as sold.
    expect(restocked.soldAt, isNull);
  });

  testWidgets('the sheet refuses a count that is not a positive number', (
    WidgetTester tester,
  ) async {
    await openActions(tester);

    await tester.tap(find.text('Restock'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, '0');
    await tester.tap(find.widgetWithText(SdButtonV3, 'Restock').last);
    await tester.pumpAndSettle();

    // The sheet stays open on a count that is not a count, so the seller can
    // correct it rather than wonder whether anything happened.
    expect(find.byType(RestockSheet), findsOneWidget);
  });
}

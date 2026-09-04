import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_detail_edit_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

import '../../support/pump_app.dart';

/// **There is no Restock verb; the count is edited on the detail screen** —
/// owner's rule. A count is a fact about the record, and a sheet that added to
/// it beside a field that replaced it was two answers to one question.
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

  Future<Item> saved(ProviderContainer container, String id) async {
    // The repository writes to a broadcast stream, so the list has to be read
    // after the write has been given a turn.
    await Future<void>.delayed(Duration.zero);

    return container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.id == id);
  }

  testWidgets('the actions sheet offers no Restock', (
    WidgetTester tester,
  ) async {
    await openActions(tester);

    expect(find.text('Restock'), findsNothing);
  });

  testWidgets('a draft is the only row offered Make it in stock', (
    WidgetTester tester,
  ) async {
    await openActions(tester);

    // The list sorts newest-created first and the top row is in stock, so the
    // row must be absent here — offering it would be a verb that does nothing.
    expect(find.text('Make it in stock'), findsNothing);
  });

  test('the detail screen puts a sold row back on the shelf', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item sold = await saved(container, 'itm-1');

    expect(sold.status, ItemStatus.sold, reason: 'the fixture must start sold');

    await container
        .read(itemDetailEditControllerProvider.notifier)
        .saveOverview(itemId: sold.id, title: sold.title, quantity: '5');

    final Item restocked = await saved(container, 'itm-1');

    expect(restocked.status, ItemStatus.inStock);
    expect(restocked.quantity, 5);
    // The sale is undone with it: a row on the shelf carrying a sold date is
    // one every export reads as sold.
    expect(restocked.soldAt, isNull);
  });
}

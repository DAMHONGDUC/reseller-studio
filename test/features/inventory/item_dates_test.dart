import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/repositories/item_repository.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';

import '../../support/pump_app.dart';

/// **Both dates are records, not fields** — owner's rule. No form offers
/// either, the row carries the last change, and the detail screen carries the
/// pair.
void main() {
  Item itemWith({DateTime? updatedAt}) => Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: testNow.subtract(const Duration(days: 40)),
    updatedAt: updatedAt,
    condition: ItemCondition.good,
  );

  testWidgets('the row says when the record last changed', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(updatedAt: testNow.subtract(const Duration(days: 2))),
        now: testNow,
      ),
    );

    expect(find.text('Updated Aug 10'), findsOneWidget);
  });

  testWidgets('a record nothing has touched says nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, ItemCard(item: itemWith(), now: testNow));

    // Dressing the creation date up as an edit would answer "did my edit
    // save?" with a yes for an item nobody has edited.
    expect(find.textContaining('Updated'), findsNothing);
  });

  testWidgets('the row carries the grade a buyer reads first', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, ItemCard(item: itemWith(), now: testNow));

    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('the detail screen shows both dates, read only', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));

    await tester.scrollUntilVisible(
      find.text('Added'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Last updated'), findsOneWidget);
  });

  test('saving stamps the moment it was written', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item item = container.read(itemsProvider).value!.first;
    final ItemRepository repository = container.read(itemRepositoryProvider);

    await repository.save(item.copyWith(title: 'Renamed'));
    await Future<void>.delayed(Duration.zero);

    final Item saved = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item row) => row.id == item.id);

    // Firestore stamps this server-side; mock mode has no server, so the
    // repository does it — otherwise the only mode the app can be developed
    // against would show "last updated" blank forever.
    expect(saved.updatedAt, isNotNull);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/widgets/mark_sold_sheet.dart';
import 'package:reseller_studio/core/widgets/price_entry_sheet.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/scan_match.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/scan_result_screen/scan_result_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_actions_sheet.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/fixtures/sample_bottles.dart';
import '../../support/pump_app.dart';

/// After a scan the seller lands on what the code named, with the next step
/// one tap away — scanned with each sample bottle.
void main() {
  Future<GoRouter> pumpResult(WidgetTester tester, String code) {
    final MockStore store = MockStore(MockDataset.seed(now: testNow))
      ..items.addAll(SampleBottles.items(now: testNow));

    return pumpRoutedScreen(
      tester,
      ScanResultScreen(code: code),
      overrides: [
        itemRepositoryProvider.overrideWithValue(InMemoryItemRepository(store)),
      ],
      replaces: <Object>{itemRepositoryProvider},
    );
  }

  testWidgets('an owned bottle shows the item and what to do with it', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpResult(
      tester,
      SampleBottles.perfume.code,
    );

    expect(find.text(SampleBottles.perfume.code), findsOneWidget);
    expect(find.text('In your inventory'), findsOneWidget);
    expect(find.text(SampleBottles.perfume.title), findsOneWidget);

    for (final String action in <String>[
      'Mark as sold',
      'Reprice',
      'Open item',
      'More actions',
    ]) {
      expect(await revealText(tester, action), findsOneWidget);
    }

    expect(find.text('Scan again'), findsOneWidget);

    await tester.tap(await revealText(tester, 'Open item'));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      AppRoutes.item(SampleBottles.perfume.itemId!),
    );
  });

  testWidgets('the flask is found as iOS reads its UPC-A', (
    WidgetTester tester,
  ) async {
    await pumpResult(tester, '0${SampleBottles.flask.code}');

    expect(find.text(SampleBottles.flask.title), findsOneWidget);
  });

  testWidgets('the unknown bottle offers to add it, keeping the code', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpResult(tester, SampleBottles.water.code);

    expect(find.text('Nothing has that code'), findsOneWidget);
    expect(await revealText(tester, 'Should I buy it?'), findsOneWidget);

    await tester.tap(await revealText(tester, 'Add an item'));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.toString(),
      AppRoutes.addItemWithCode(code: SampleBottles.water.code),
    );
  });

  testWidgets('a bin label lists the bottle stored on it', (
    WidgetTester tester,
  ) async {
    await pumpResult(tester, 'BIN-A1');

    expect(find.text('A storage location'), findsOneWidget);
    expect(await revealText(tester, 'Stored here'), findsOneWidget);
    expect(await revealText(tester, SampleBottles.flask.title), findsOneWidget);
  });

  group('actions on an owned bottle', () {
    testWidgets('Mark as sold opens the sale sheet for that item', (
      WidgetTester tester,
    ) async {
      await pumpResult(tester, SampleBottles.perfume.code);

      await tester.tap(await revealText(tester, 'Mark as sold'));
      await tester.pumpAndSettle();

      expect(find.byType(MarkSoldSheet), findsOneWidget);
    });

    testWidgets('Reprice opens the reprice sheet', (WidgetTester tester) async {
      await pumpResult(tester, SampleBottles.perfume.code);

      await tester.tap(await revealText(tester, 'Reprice'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceEntrySheet), findsOneWidget);
    });

    testWidgets('More actions opens every action on the item', (
      WidgetTester tester,
    ) async {
      await pumpResult(tester, SampleBottles.perfume.code);

      await tester.tap(await revealText(tester, 'More actions'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemActionsSheet), findsOneWidget);
      expect(find.text('Move'), findsWidgets);
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('tapping the item card opens the item', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpResult(
        tester,
        SampleBottles.perfume.code,
      );

      await tester.tap(find.text(SampleBottles.perfume.title));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.path,
        AppRoutes.item(SampleBottles.perfume.itemId!),
      );
    });
  });

  testWidgets('the unknown bottle can go to the buy calculator with its code', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpResult(tester, SampleBottles.water.code);

    await tester.tap(await revealText(tester, 'Should I buy it?'));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.toString(),
      AppRoutes.evaluate(code: SampleBottles.water.code),
    );
  });

  test('while inventory loads it waits, never says "no match"', () async {
    final StreamController<List<Item>> items = StreamController<List<Item>>();
    final ProviderContainer container = mockContainer(
      overrides: [itemsProvider.overrideWith((Ref ref) => items.stream)],
    );
    final ProviderSubscription<ScanMatch?> match = container.listen(
      scanMatchProvider(SampleBottles.perfume.code),
      (ScanMatch? previous, ScanMatch? next) {},
    );

    addTearDown(items.close);
    await pumpEventQueue();

    // Null is the loading answer: the screen shows its spinner for it.
    expect(match.read(), isNull);

    items.add(SampleBottles.items(now: testNow));
    await pumpEventQueue();

    expect(match.read(), isA<ScanMatchItem>());
  });

  testWidgets('a bin with nothing on it says so', (WidgetTester tester) async {
    await pumpResult(tester, 'BIN-A2');

    expect(
      await revealText(tester, 'Nothing is stored here right now.'),
      findsOneWidget,
    );
  });
}

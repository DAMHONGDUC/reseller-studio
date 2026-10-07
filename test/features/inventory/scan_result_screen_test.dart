import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/scan_result_screen/scan_result_screen.dart';

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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/scan_result_screen/scan_result_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/scanner_screen/scanner_screen.dart';

import '../../support/fakes/fake_scanner_platform.dart';
import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/fixtures/sample_bottles.dart';
import '../../support/pump_app.dart';

/// The scan, end to end: the real scanner and result screens on one router,
/// a sample bottle held up to a fake camera, and every way back.
void main() {
  late FakeScannerPlatform camera;
  late GoRouter router;

  setUp(() {
    camera = FakeScannerPlatform.install();
    router = GoRouter(
      initialLocation: AppRoutes.scanner,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.scanner,
          builder: (BuildContext context, GoRouterState state) =>
              const ScannerScreen(),
        ),
        GoRoute(
          path: AppRoutes.scanResultPath,
          builder: (BuildContext context, GoRouterState state) =>
              ScanResultScreen(code: state.uri.queryParameters['code'] ?? ''),
        ),
        // Every other destination: a page that names where it is.
        GoRoute(
          path: '/:destination(.*)',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: Text(state.uri.toString(), style: const TextStyle()),
          ),
        ),
      ],
    );
  });

  Future<void> pumpFlow(WidgetTester tester) {
    final MockStore store = MockStore(MockDataset.seed(now: testNow))
      ..items.addAll(SampleBottles.items(now: testNow));

    return pumpRouter(
      tester,
      router,
      overrides: [
        itemRepositoryProvider.overrideWithValue(InMemoryItemRepository(store)),
      ],
      replaces: <Object>{itemRepositoryProvider},
    );
  }

  Future<void> hold(WidgetTester tester, String code) async {
    camera.scan(code);
    await tester.pumpAndSettle();
  }

  String location() => router.state.uri.toString();

  testWidgets('a bottle lands on its result, with the camera off', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, SampleBottles.perfume.code);

    expect(location(), AppRoutes.scanResult(SampleBottles.perfume.code));
    expect(find.text(SampleBottles.perfume.title), findsOneWidget);
    expect(camera.calls.last, 'stop');
  });

  testWidgets('Scan again goes back to a camera that reads the next one', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, SampleBottles.perfume.code);

    await tester.tap(find.text('Scan again'));
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.scanner);
    expect(camera.calls.last, 'start');

    await hold(tester, SampleBottles.water.code);

    expect(location(), AppRoutes.scanResult(SampleBottles.water.code));
    expect(find.text('Nothing has that code'), findsOneWidget);
  });

  testWidgets('back from the result is scanning again too', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, SampleBottles.cola.code);

    router.pop();
    await tester.pumpAndSettle();
    await hold(tester, SampleBottles.flask.code);

    expect(find.text(SampleBottles.flask.title), findsOneWidget);
  });

  testWidgets('every bottle, one after another, lands on the right answer', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);

    for (final SampleBottle bottle in SampleBottles.all) {
      await hold(tester, bottle.code);

      expect(location(), AppRoutes.scanResult(bottle.code));
      expect(
        find.text(
          bottle.itemId == null ? 'Nothing has that code' : bottle.title,
        ),
        findsOneWidget,
        reason: bottle.slug,
      );

      await tester.tap(find.text('Scan again'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the UPC-A as iOS reads it still finds the flask', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, '0${SampleBottles.flask.code}');

    expect(find.text(SampleBottles.flask.title), findsOneWidget);
  });

  testWidgets('opening the item and coming back keeps the result', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, SampleBottles.perfume.code);

    await tester.tap(await revealText(tester, 'Open item'));
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.item(SampleBottles.perfume.itemId!));

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text(SampleBottles.perfume.title), findsOneWidget);
    expect(camera.calls.last, 'stop', reason: 'still covered by the result');
  });

  testWidgets('a code with characters a URL cares about survives the trip', (
    WidgetTester tester,
  ) async {
    await pumpFlow(tester);
    await hold(tester, 'https://bin.example/a b?x=1&y=2');

    expect(find.text('https://bin.example/a b?x=1&y=2'), findsOneWidget);
  });
}

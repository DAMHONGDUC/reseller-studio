import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/router/app_navigator_key.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/scan_match.dart';
import 'package:reseller_studio/features/inventory/domain/entities/storage_location.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/scan_lookup.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/fakes/mock_dataset.dart';
import '../../support/fixtures/sample_bottles.dart';
import '../../support/pump_app.dart';

/// The edges of turning a read into a record — the cases a camera produces
/// that a tidy fixture does not.
void main() {
  final MockDataset dataset = MockDataset.seed(now: testNow);
  final List<Item> bottles = SampleBottles.items(now: testNow);
  final Item perfume = bottles[0];
  final Item flask = bottles[1];

  ScanMatch scan(
    String code, {
    List<Item>? items,
    List<StorageLocation>? locations,
  }) => ScanLookup.resolve(
    code,
    items: items ?? bottles,
    locations: locations ?? dataset.locations,
  );

  String? itemId(ScanMatch match) =>
      match is ScanMatchItem ? match.item.id : null;

  test('a read with stray whitespace still matches', () {
    expect(itemId(scan('  ${perfume.barcode}\n')), perfume.id);
  });

  test('the result keeps the code exactly as read', () {
    expect(scan('0${flask.barcode}').code, '0${flask.barcode}');
  });

  test('an item wins over a bin that carries the same label', () {
    final Item labelled = perfume.copyWith(sku: 'BIN-A1');

    expect(itemId(scan('BIN-A1', items: <Item>[labelled])), perfume.id);
  });

  test('a sold item has left the bin it was stored in', () {
    final ScanMatch match = scan(
      'BIN-A1',
      items: <Item>[flask.copyWith(status: ItemStatus.sold)],
    );

    expect((match as ScanMatchLocation).items, isEmpty);
  });

  test('a deleted bin is not found', () {
    final List<StorageLocation> deleted = <StorageLocation>[
      for (final StorageLocation location in dataset.locations)
        location.copyWith(deletedAt: testNow),
    ];

    expect(scan('BIN-A1', locations: deleted), isA<ScanMatchNone>());
  });

  group('only a UPC-A has two spellings', () {
    test('thirteen digits not starting with 0 are never shortened', () {
      final Item shortened = perfume.copyWith(barcode: '006381333931');

      expect(
        scan('4006381333931', items: <Item>[shortened]),
        isA<ScanMatchNone>(),
      );
    });

    test('an EAN-8 is not padded', () {
      final Item padded = perfume.copyWith(barcode: '096385074');

      expect(scan('96385074', items: <Item>[padded]), isA<ScanMatchNone>());
    });

    test('twelve letters are not a UPC-A', () {
      final Item prefixed = perfume.copyWith(barcode: '0ABCDEFGHIJKL');

      expect(
        scan('ABCDEFGHIJKL', items: <Item>[prefixed]),
        isA<ScanMatchNone>(),
      );
    });
  });

  group('the route', () {
    test('escapes the code, which can be any text a label carries', () {
      expect(
        AppRoutes.scanResult('a b/c?d=1&e'),
        '${AppRoutes.scanResultPath}?code=a%20b%2Fc%3Fd%3D1%26e',
      );
    });

    test('the app router answers it, above the tab bar', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          isSignedInProvider.overrideWithValue(true),
          workspaceStatusProvider.overrideWithValue(WorkspaceStatus.ready),
        ],
      );

      addTearDown(container.dispose);

      final GoRouter router = container.read(routerProvider);
      final RouteMatchList match = router.configuration.findMatch(
        Uri.parse(AppRoutes.scanResult('5901234123457')),
      );
      final GoRoute route = match.last.route;

      expect(match.isError, isFalse);
      expect(match.uri.path, AppRoutes.scanResultPath);
      expect(match.uri.queryParameters['code'], '5901234123457');
      expect(route.parentNavigatorKey, AppNavigatorKey.root);
    });
  });
}

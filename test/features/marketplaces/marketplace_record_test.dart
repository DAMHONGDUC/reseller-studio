import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart'
    as mock_providers;
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart'
    as record;
import 'package:reseller_studio/features/marketplaces/domain/repositories/marketplace_repository.dart';
import 'package:reseller_studio/features/marketplaces/presentation/controllers/marketplace_form_controller.dart';
import 'package:reseller_studio/features/marketplaces/presentation/screens/marketplace_detail_screen/marketplace_detail_screen.dart';
import 'package:reseller_studio/features/marketplaces/presentation/screens/marketplaces_screen/marketplaces_screen.dart';
import 'package:reseller_studio/features/marketplaces/providers.dart';

import '../../support/pump_app.dart';

void main() {
  group('seller-owned marketplaces', () {
    test('a new business receives the five defaults', () {
      final ProviderContainer container = mockContainer();
      final List<record.Marketplace> defaults = container.read(
        defaultMarketplacesProvider,
      );

      expect(defaults.map((record.Marketplace row) => row.name), <String>[
        'eBay',
        'Etsy',
        'Depop',
        'Poshmark',
        'Vinted',
      ]);
    });

    testWidgets('the list has add and detail rows but no publish toggle', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const MarketplacesScreen());

      expect(find.text('Add marketplace'), findsOneWidget);
      expect(find.text('eBay'), findsOneWidget);
      expect(find.text('Poshmark'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('detail edits the name and the colour', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const MarketplaceDetailScreen(marketplaceId: 'ebay'),
      );

      expect(find.text('Edit marketplace'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'eBay'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('saving an existing marketplace renames it', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const MarketplaceDetailScreen(marketplaceId: 'ebay'),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MarketplaceDetailScreen)),
      );

      await tester.enterText(find.widgetWithText(TextField, 'eBay'), 'eBay UK');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final MarketplaceRepository repository = container.read(
        mock_providers.marketplaceRepositoryProvider,
      );
      final record.Marketplace changed =
          (await repository.watchMarketplaces().first).firstWhere(
            (record.Marketplace row) => row.id == 'ebay',
          );

      expect(changed.name, 'eBay UK');
    });

    testWidgets('saving stays busy until the write lands', (
      WidgetTester tester,
    ) async {
      final _DelayedMarketplaceRepository repository =
          _DelayedMarketplaceRepository();
      await pumpScreen(
        tester,
        const MarketplaceDetailScreen(marketplaceId: 'ebay'),
        overrides: <Override>[
          mock_providers.marketplaceRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
        replaces: <Object>{mock_providers.marketplaceRepositoryProvider},
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      repository.completeSave();
      await tester.pumpAndSettle();

      expect(repository.saved?.id, 'ebay');
    });

    testWidgets('add mode has no delete action', (WidgetTester tester) async {
      await pumpScreen(tester, const MarketplaceDetailScreen());

      expect(find.byTooltip('Delete'), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    test('the form controller can add a normal marketplace record', () async {
      final ProviderContainer container = mockContainer();
      final MarketplaceFormController controller = container.read(
        marketplaceFormControllerProvider.notifier,
      );
      final MarketplaceRepository repository = container.read(
        mock_providers.marketplaceRepositoryProvider,
      );

      controller.startCreate();
      final String? id = await controller.submit(name: 'Mercari');
      final List<record.Marketplace> rows = await repository
          .watchMarketplaces()
          .first;

      expect(id, isNotNull);
      expect(
        rows.where((record.Marketplace row) => row.name == 'Mercari'),
        hasLength(1),
      );
    });

    test('the form controller refuses an empty name', () async {
      final ProviderContainer container = mockContainer();
      final MarketplaceFormController controller = container.read(
        marketplaceFormControllerProvider.notifier,
      );
      final MarketplaceRepository repository = container.read(
        mock_providers.marketplaceRepositoryProvider,
      );
      final int countBefore =
          (await repository.watchMarketplaces().first).length;

      controller.startCreate();
      final String? id = await controller.submit(name: '   ');
      final int countAfter =
          (await repository.watchMarketplaces().first).length;

      expect(id, isNull);
      expect(countAfter, countBefore);
    });

    test('the form controller edits and soft-deletes a marketplace', () async {
      final ProviderContainer container = mockContainer();
      final MarketplaceFormController controller = container.read(
        marketplaceFormControllerProvider.notifier,
      );
      final MarketplaceRepository repository = container.read(
        mock_providers.marketplaceRepositoryProvider,
      );
      final record.Marketplace ebay =
          (await repository.watchMarketplaces().first).firstWhere(
            (record.Marketplace row) => row.id == 'ebay',
          );

      controller.seed(ebay);
      await controller.submit(name: 'eBay UK', marketplaceId: ebay.id);
      record.Marketplace changed = (await repository.watchMarketplaces().first)
          .firstWhere((record.Marketplace row) => row.id == ebay.id);

      expect(changed.name, 'eBay UK');

      await controller.delete(ebay.id);
      changed = (await repository.watchMarketplaces().first).firstWhere(
        (record.Marketplace row) => row.id == ebay.id,
      );

      expect(changed.isDeleted, isTrue);
    });
  });
}

class _DelayedMarketplaceRepository implements MarketplaceRepository {
  final Completer<void> _saveGate = Completer<void>();
  final record.Marketplace _marketplace = record.Marketplace(
    id: 'ebay',
    name: 'eBay',
    createdAt: testNow,
  );

  record.Marketplace? saved;

  void completeSave() => _saveGate.complete();

  @override
  Future<void> delete(String marketplaceId) async {}

  @override
  Future<void> save(record.Marketplace marketplace) async {
    await _saveGate.future;
    saved = marketplace;
  }

  @override
  Future<void> saveAll(List<record.Marketplace> marketplaces) async {
    await _saveGate.future;
    saved = marketplaces.isEmpty ? null : marketplaces.first;
  }

  @override
  Stream<List<record.Marketplace>> watchMarketplaces() =>
      Stream<List<record.Marketplace>>.value(<record.Marketplace>[
        saved ?? _marketplace,
      ]);
}

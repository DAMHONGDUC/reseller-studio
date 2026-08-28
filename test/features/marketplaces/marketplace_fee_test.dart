import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart'
    as record;
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/domain/repositories/marketplace_repository.dart';
import 'package:reseller_studio/features/marketplaces/domain/services/marketplace_fee_policy.dart';
import 'package:reseller_studio/features/marketplaces/presentation/controllers/marketplace_form_controller.dart';
import 'package:reseller_studio/features/marketplaces/presentation/screens/marketplace_detail_screen/marketplace_detail_screen.dart';
import 'package:reseller_studio/features/marketplaces/presentation/screens/marketplaces_screen/marketplaces_screen.dart';
import 'package:reseller_studio/features/marketplaces/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart'
    as mock_providers;
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';

import '../../support/pump_app.dart';

void main() {
  Order order({Money? fees}) => Order(
    id: 'o-1',
    status: OrderStatus.delivered,
    marketplace: Marketplace.ebay,
    lines: const <OrderLine>[],
    salePrice: const Money(10000, 'USD'),
    orderedAt: testNow,
    fees: fees,
  );

  group('legacy order estimates', () {
    test('a correction wins when an order reports no fee', () {
      expect(
        PayoutReconciliation.expected(
          order(),
          feeRates: const <String, double>{'ebay': 0.08},
        ),
        const Money(9200, 'USD'),
      );
    });

    test('a reported fee still wins over an estimate', () {
      expect(
        PayoutReconciliation.expected(
          order(fees: const Money(500, 'USD')),
          feeRates: const <String, double>{'ebay': 0.08},
        ),
        const Money(9500, 'USD'),
      );
    });

    test('a rate outside 0–100% is invalid', () {
      expect(MarketplaceFeePolicy.isValid(0), isTrue);
      expect(MarketplaceFeePolicy.isValid(1), isTrue);
      expect(MarketplaceFeePolicy.isValid(-0.01), isFalse);
      expect(MarketplaceFeePolicy.isValid(1.5), isFalse);
    });
  });

  group('seller-owned marketplaces', () {
    test('a new business receives the five defaults with rates', () {
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
      expect(
        <String, double>{
          for (final record.Marketplace row in defaults) row.name: row.feeRate,
        },
        <String, double>{
          'eBay': 0.1325,
          'Etsy': 0.095,
          'Depop': 0.10,
          'Poshmark': 0.20,
          'Vinted': 0,
        },
      );
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

    testWidgets('detail edits name and estimated rate together', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const MarketplaceDetailScreen(marketplaceId: 'ebay'),
      );

      expect(find.text('Edit marketplace'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'eBay'), findsOneWidget);
      expect(find.widgetWithText(TextField, '13.25'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
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
      controller.updateFeeRate(0.12);
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
      controller.updateFeeRate(0.15);
      await controller.submit(name: 'eBay UK', marketplaceId: ebay.id);
      record.Marketplace changed = (await repository.watchMarketplaces().first)
          .firstWhere((record.Marketplace row) => row.id == ebay.id);

      expect(changed.name, 'eBay UK');
      expect(changed.feeRate, 0.15);

      await controller.delete(ebay.id);
      changed = (await repository.watchMarketplaces().first).firstWhere(
        (record.Marketplace row) => row.id == ebay.id,
      );

      expect(changed.isDeleted, isTrue);
    });
  });
}

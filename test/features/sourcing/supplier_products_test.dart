import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/supplier_product.dart';
import 'package:reseller_studio/features/sourcing/domain/services/supplier_cost.dart';
import 'package:reseller_studio/features/sourcing/presentation/controllers/supplier_product_controller.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/supplier_product_screen/supplier_product_screen.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/suppliers_screen/suppliers_screen.dart';
import 'package:reseller_studio/features/sourcing/providers.dart';

import '../../support/add_button_finder.dart';
import '../../support/pump_app.dart';

/// Dropship suppliers and their products: what an order costs, listing one
/// as an item, and ranking a backup.
void main() {
  SupplierProduct product({
    String id = 'sp-1',
    int? price = 1200,
    int? shipping = 300,
    int? tax,
    String? itemId,
    int rank = 1,
  }) => SupplierProduct(
    id: id,
    sourceId: 'cj',
    title: 'Trucker jacket',
    createdAt: DateTime(2026, 10, 1),
    itemId: itemId,
    rank: rank,
    supplierPrice: price == null ? null : Money(price, 'USD'),
    supplierShipping: shipping == null ? null : Money(shipping, 'USD'),
    supplierTax: tax == null ? null : Money(tax, 'USD'),
  );

  group('SupplierCost', () {
    test('an order costs price, shipping and tax together', () {
      expect(SupplierCost.landed(product(tax: 100)), const Money(1600, 'USD'));
    });

    test('no shipping or tax adds nothing; no price is no cost', () {
      expect(
        SupplierCost.landed(product(shipping: null)),
        const Money(1200, 'USD'),
      );
      expect(SupplierCost.landed(product(price: null)), isNull);
    });

    test('figures older than the window, or never checked, need a recheck', () {
      final DateTime now = DateTime(2026, 10, 30);

      expect(SupplierCost.needsRecheck(product(), now, afterDays: 14), isTrue);
      expect(
        SupplierCost.needsRecheck(
          product().copyWith(lastCheckedAt: DateTime(2026, 10, 20)),
          now,
          afterDays: 14,
        ),
        isFalse,
      );
    });

    test('the primary is the lowest live rank', () {
      expect(
        SupplierCost.primaryFor('itm', <SupplierProduct>[
          product(id: 'b', itemId: 'itm', rank: 2),
          product(id: 'a', itemId: 'itm'),
        ])?.id,
        'a',
      );
    });
  });

  group('SupplierProductController', () {
    test('List it creates a dropship item and links the product', () async {
      final ProviderContainer container = mockContainer();

      container
        ..listen(supplierProductsProvider, (_, _) {}, fireImmediately: true)
        ..listen(itemsProvider, (_, _) {}, fireImmediately: true);
      // Let the fake streams subscribe to changes before anything is written.
      await Future<void>.delayed(Duration.zero);

      final String itemId = await container
          .read(supplierProductControllerProvider.notifier)
          .listIt(product());
      await Future<void>.delayed(Duration.zero);

      final Item item = container
          .read(itemsProvider)
          .value!
          .firstWhere((Item item) => item.id == itemId);

      expect(item.isDropship, isTrue);
      expect(item.title, 'Trucker jacket');
      expect(
        container.read(supplierProductsForItemProvider(itemId)).single.id,
        'sp-1',
      );
      expect(
        container.read(dropshipCostProvider(itemId)),
        const Money(1500, 'USD'),
      );
    });

    test('making a backup primary moves the old primary down', () async {
      final ProviderContainer container = mockContainer();
      final SupplierProductController controller = container.read(
        supplierProductControllerProvider.notifier,
      );
      final List<SupplierProduct> linked = <SupplierProduct>[
        product(id: 'a', itemId: 'itm'),
        product(id: 'b', itemId: 'itm', rank: 2),
      ];

      container.listen(
        supplierProductsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      for (final SupplierProduct p in linked) {
        await controller.save(p);
      }
      await controller.makePrimary(linked[1], linked);
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(supplierProductsForItemProvider('itm'))
            .map((SupplierProduct p) => p.id),
        <String>['b', 'a'],
      );
    });
  });

  testWidgets('a business with no supplier is invited to add one', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SuppliersScreen());

    expect(find.text('No suppliers yet'), findsOneWidget);
    expect(AddButtonFinder.named('Add supplier'), findsOneWidget);
  });

  testWidgets('Clean up strips supplier filler from the title', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SupplierProductScreen(sourceId: 'cj'));

    await tester.enterText(
      find.byType(TextField).first,
      'Hot Sale 2026 New Women Summer Dress Free Shipping',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clean up'));
    await tester.pumpAndSettle();

    expect(find.text('Women Summer Dress'), findsOneWidget);
  });
}

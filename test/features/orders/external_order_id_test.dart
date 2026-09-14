import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_csv_import.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/order_detail_edit_controller.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// The platform's own order number, from the sale that creates the order to
/// the payout file that matches it.
///
/// **This is the whole chain, and it used to have no beginning.** Nothing in
/// the app wrote `Order.externalOrderId`, so every manually recorded sale —
/// which is all of them, because connecting to a marketplace is not a feature
/// (hard rule 10) — could never be matched by `PayoutCsvImport`. A file the
/// seller exported matched zero rows, every time.
void main() {
  test('a sale records the order number the seller typed', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item item = container.read(sellableItemsProvider).first;

    final String orderId = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[item],
          salePrice: const Money(3200, 'USD'),
          marketplaceId: 'ebay',
          marketplaceName: 'eBay',
          soldAt: testNow,
          externalOrderId: '11-12874-59921',
        );

    final Order written = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order order) => order.id == orderId);

    expect(written.externalOrderId, '11-12874-59921');
  });

  test('a sale without one stays null rather than empty', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item item = container.read(sellableItemsProvider).first;

    final String orderId = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[item],
          salePrice: const Money(3200, 'USD'),
          marketplaceId: 'ebay',
          marketplaceName: 'eBay',
          soldAt: testNow,
        );

    final Order written = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order order) => order.id == orderId);

    expect(written.externalOrderId, isNull);
  });

  test('a pasted payout report matches the sale that carries one', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item item = container.read(sellableItemsProvider).first;

    await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[item],
          salePrice: const Money(3200, 'USD'),
          marketplaceId: 'ebay',
          marketplaceName: 'eBay',
          soldAt: testNow,
          externalOrderId: '11-12874-59921',
        );

    // Shaped the way eBay exports one.
    const String csv =
        'Sales Record Number,Order Number,Item title,Sold for,Order earnings\n'
        '11-12874-59921,11-12874-59921,Hand-thrown mug,32.00,27.44\n';

    final PayoutCsvResult read = PayoutCsvImport.parse(csv, currency: 'USD');
    final PayoutCsvMatch match = PayoutCsvImport.against(
      container.read(ordersAwaitingPayoutListProvider),
      read.rows,
    );

    expect(match.matchedCount, 1);
    expect(match.payoutsByOrderId.values.single, const Money(2744, 'USD'));
  });

  test('the order number can be corrected afterwards', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item item = container.read(sellableItemsProvider).first;

    final String orderId = await container
        .read(recordSaleControllerProvider.notifier)
        .record(
          <Item>[item],
          salePrice: const Money(3200, 'USD'),
          marketplaceId: 'ebay',
          marketplaceName: 'eBay',
          soldAt: testNow,
        );

    await container
        .read(orderDetailEditControllerProvider.notifier)
        .saveOrder(
          orderId: orderId,
          buyerName: '',
          salePrice: '32.00',
          externalOrderId: '11-12874-59921',
        );

    final Order written = container
        .read(ordersProvider)
        .value!
        .firstWhere((Order order) => order.id == orderId);

    expect(written.externalOrderId, '11-12874-59921');
  });
}

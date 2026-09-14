import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

import '../../support/pump_app.dart';

/// What the two Free ceilings actually count.
///
/// **They count differently on purpose.** Items are a lifetime total, so a
/// sold row keeps its slot; orders are a rate, so a sale that falls out of the
/// window gives its slot back with no action from the seller. The old
/// arrangement was the other way round on both, and it walled a seller in at
/// their thirty-first sale with no way out.
void main() {
  Future<String> sell(
    ProviderContainer container,
    Item item, {
    required DateTime on,
  }) => container
      .read(recordSaleControllerProvider.notifier)
      .record(
        <Item>[item],
        salePrice: const Money(3200, 'USD'),
        marketplaceId: 'ebay',
        marketplaceName: 'eBay',
        soldAt: on,
      );

  test('a sold item keeps its slot — the item ceiling is a lifetime', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int before = container.read(countedItemsProvider);
    final Item item = container.read(sellableItemsProvider).first;

    await sell(container, item, on: testNow);

    expect(
      container.read(countedItemsProvider),
      before,
      reason: 'selling frees no slot; only deleting a row does',
    );
  });

  test('orders older than the window stop counting', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int before = container.read(countedOrdersProvider);
    final Item recent = container.read(sellableItemsProvider).first;

    await sell(container, recent, on: testNow);

    expect(container.read(countedOrdersProvider), before + 1);

    final Item old = container.read(sellableItemsProvider).first;

    await sell(
      container,
      old,
      on: testNow.subtract(PlanLimits.orderWindow + const Duration(days: 1)),
    );

    expect(
      container.read(countedOrdersProvider),
      before + 1,
      reason: 'a sale outside the window is not this month\'s trading',
    );
    expect(
      container.read(ordersProvider).value, // still on the books, still read
      hasLength(greaterThan(before + 1)),
    );
  });

  test('the gate follows the window rather than the history', () async {
    // The ceiling is the one in the table, whatever it is set to: what this
    // pins is that a full window blocks and an emptied one does not.
    final int ceiling = PlanLimits.of(SellerPlan.free).orders!;

    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: ceiling - 1),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: ceiling),
      PlanBlock.orderLimit,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.premium, currentOrders: ceiling * 100),
      PlanBlock.none,
    );
  });

  test('the window is a rate, and the app states it once', () {
    expect(PlanLimits.orderWindow, const Duration(days: 30));
    expect(PlanLimits.of(SellerPlan.free).items, isNotNull);
    expect(PlanLimits.of(SellerPlan.premium).orders, isNull);
  });
}

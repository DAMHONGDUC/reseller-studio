import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_actions_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_form_controller.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';
import 'package:reseller_studio/features/sourcing/presentation/controllers/sourcing_controller.dart';
import 'package:reseller_studio/features/sourcing/providers.dart';

import '../../support/pump_app.dart';

/// SOURCE → PURCHASE → INVENTORY, the half that had no wiring.
///
/// An item could name a source and a date but never the purchase itself, so a
/// receipt sat alone: Books called every trip unfiled and Sourcing ranked
/// every source with no return. The purchase screen's own empty state told
/// the seller to set it "on the item form", where no such field existed.
void main() {
  Purchase purchaseOf(ProviderContainer container) =>
      container.read(purchasesProvider).value!.first;

  List<Item> itemsOf(ProviderContainer container, String purchaseId) =>
      container
          .read(itemsProvider)
          .value!
          .where((Item item) => item.purchaseId == purchaseId)
          .toList();

  test('picking a trip carries its source and date onto the item', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Purchase purchase = purchaseOf(container);

    container
        .read(itemFormControllerProvider.notifier)
        .selectPurchase(purchase.id);

    final ItemFormState state = container.read(itemFormControllerProvider);

    expect(state.purchaseId, purchase.id);
    expect(state.sourceId, purchase.sourceId);
    expect(state.purchaseDate, purchase.purchaseDate);
  });

  test('a batch can be filed under one trip at once', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Purchase purchase = purchaseOf(container);
    final List<Item> unfiled = container
        .read(itemsProvider)
        .value!
        .where((Item item) => item.purchaseId == null)
        .take(2)
        .toList();

    expect(unfiled, isNotEmpty, reason: 'the seed keeps Quick Add leftovers');

    await container
        .read(itemActionsControllerProvider.notifier)
        .assignPurchase(unfiled, purchase);

    final List<Item> filed = itemsOf(container, purchase.id);

    expect(
      filed.map((Item item) => item.id),
      containsAll(unfiled.map((Item item) => item.id)),
    );
    expect(
      filed
          .where((Item item) => unfiled.any((Item one) => one.id == item.id))
          .every((Item item) => item.sourceId == purchase.sourceId),
      isTrue,
    );
  });

  test('filing a batch brings the purchase\'s item count with it', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Purchase purchase = purchaseOf(container);
    final List<Item> unfiled = container
        .read(itemsProvider)
        .value!
        .where((Item item) => item.purchaseId == null)
        .take(2)
        .toList();

    await container
        .read(itemActionsControllerProvider.notifier)
        .assignPurchase(unfiled, purchase);

    final Purchase after = container
        .read(purchasesProvider)
        .value!
        .firstWhere((Purchase row) => row.id == purchase.id);

    expect(
      after.itemCount,
      itemsOf(container, purchase.id).length,
      reason:
          'the count Books and Purchases read is denormalised, so filing '
          'items has to keep it in step — it used to read 0 beside twelve',
    );
  });

  test('the receipt spreads across the items and adds back up', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Purchase purchase = purchaseOf(container);
    final List<Item> filed = itemsOf(container, purchase.id);

    expect(filed, isNotEmpty);

    const Money total = Money(24000, 'USD');

    await container
        .read(sourcingControllerProvider.notifier)
        .apportion(filed, total);

    final List<Money?> costs = itemsOf(
      container,
      purchase.id,
    ).map((Item item) => item.purchasePrice).toList();

    expect(costs.every((Money? cost) => cost != null), isTrue);
    expect(
      costs.cast<Money>().reduce((Money a, Money b) => a + b),
      total,
      reason: 'every penny of the receipt lands on an item',
    );
  });

  test('apportioning nothing writes nothing', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    await container
        .read(sourcingControllerProvider.notifier)
        .apportion(const <Item>[], const Money(24000, 'USD'));

    expect(container.read(sourcingControllerProvider), isFalse);
  });
}

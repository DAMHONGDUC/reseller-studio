import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/presentation/controllers/offer_actions_controller.dart';
import 'package:reseller_studio/features/offers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// Accept, decline, counter (plan §8, §30).
///
/// **Accepting creates the order.** An accepted offer that produced no order
/// would vanish from every profit figure in the app, and the amount recorded
/// is the one the buyer agreed to — not the asking price.
void main() {
  Future<ProviderContainer> withOffers() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    return container;
  }

  List<Offer> offersIn(ProviderContainer container) =>
      container.read(offersProvider).value ?? const <Offer>[];

  List<Order> ordersIn(ProviderContainer container) =>
      container.read(ordersProvider).value ?? const <Order>[];

  Offer offer(ProviderContainer container, String id) =>
      offersIn(container).firstWhere((Offer row) => row.id == id);

  OfferActionsController actions(ProviderContainer container) =>
      container.read(offerActionsControllerProvider.notifier);

  test('accepting sells the item at the offered amount', () async {
    final ProviderContainer container = await withOffers();
    final Offer pending = offer(container, 'off-2');
    final int before = ordersIn(container).length;

    await actions(container).accept(pending);
    await Future<void>.delayed(Duration.zero);

    final List<Order> orders = ordersIn(container);
    final Order created = orders.firstWhere(
      (Order order) =>
          order.lines.any((OrderLine line) => line.itemId == pending.itemId),
      orElse: () => orders.last,
    );

    expect(orders, hasLength(before + 1));
    // The offered amount, never the asking price: recording anything else
    // would overstate revenue.
    expect(created.salePrice, pending.amount);
    // The order records the marketplace by id and keeps the name it sold
    // under; the legacy enum on the entity is not where that lives.
    expect(created.marketplaceId, pending.marketplace.name);
    expect(offer(container, 'off-2').status, OfferStatus.accepted);
    expect(container.read(offerActionsControllerProvider), isFalse);
  });

  test('accepting takes one off the shelf, not the whole line', () async {
    final ProviderContainer container = await withOffers();
    final Offer pending = offer(container, 'off-2');
    final Item before = (await container
        .read(itemRepositoryProvider)
        .findById(pending.itemId))!;

    await actions(container).accept(pending);
    await Future<void>.delayed(Duration.zero);

    final Item after = (await container
        .read(itemRepositoryProvider)
        .findById(pending.itemId))!;

    // Two of this one were on the shelf: an offer is for one, so the rest
    // stays sellable rather than the whole line going with it.
    expect(before.quantity, 2);
    expect(after.quantity, 1);
    expect(after.status, ItemStatus.inStock);
  });

  test('an offer whose item is gone records the decision only', () async {
    final ProviderContainer container = await withOffers();
    final Offer source = offer(container, 'off-2');
    final Offer orphan = Offer(
      id: source.id,
      itemId: 'no-such-item',
      itemTitle: source.itemTitle,
      marketplace: source.marketplace,
      amount: source.amount,
      status: source.status,
      createdAt: source.createdAt,
    );
    final int before = ordersIn(container).length;

    await actions(container).accept(orphan);
    await Future<void>.delayed(Duration.zero);

    // Inventing an order for a thing that no longer exists is the one thing
    // this must not do.
    expect(ordersIn(container), hasLength(before));
    expect(offer(container, 'off-2').status, OfferStatus.accepted);
  });

  test('declining moves the offer and sells nothing', () async {
    final ProviderContainer container = await withOffers();
    final int before = ordersIn(container).length;

    await actions(container).decline(offer(container, 'off-1'));
    await Future<void>.delayed(Duration.zero);

    expect(offer(container, 'off-1').status, OfferStatus.declined);
    expect(offer(container, 'off-1').respondedAt, isNotNull);
    expect(ordersIn(container), hasLength(before));
  });

  test('a counter is recorded, never sent', () async {
    final ProviderContainer container = await withOffers();
    const Money counter = Money(1800, 'USD');

    await actions(container).counter(offer(container, 'off-1'), counter);
    await Future<void>.delayed(Duration.zero);

    // Nothing is integrated (hard rule 10), so the app notes what the seller
    // came back with and does not claim to have replied to the buyer.
    expect(offer(container, 'off-1').status, OfferStatus.countered);
    expect(offer(container, 'off-1').counterAmount, counter);
    expect(ordersIn(container), hasLength(6));
  });

  test('every pending offer in the seed can actually be accepted', () async {
    final ProviderContainer container = await withOffers();
    final List<Offer> pending = offersIn(
      container,
    ).where((Offer row) => row.status == OfferStatus.pending).toList();

    expect(pending, isNotEmpty);

    // An offer on something already sold is a row Needs Attention shows and
    // the app then refuses — so the fixture must not contain one, and nor
    // must anything that seeds a real workspace from it.
    for (final Offer row in pending) {
      final Item? item = await container
          .read(itemRepositoryProvider)
          .findById(row.itemId);

      expect(item, isNotNull, reason: '${row.id} names a missing item');
      expect(
        item!.status,
        isNot(ItemStatus.sold),
        reason: '${row.id} is on an item that has already sold',
      );
      expect(item.quantity, greaterThan(0), reason: '${row.id} has none left');
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_transition.dart';

void main() {
  final DateTime now = DateTime(2026, 8, 12);

  Item item({
    ItemStatus status = ItemStatus.inStock,
    Money? askingPrice,
    int quantity = 1,
    DateTime? listedAt,
    DateTime? soldAt,
  }) => Item(
    id: 'i1',
    title: 'Nike Air Max 90',
    quantity: quantity,
    status: status,
    createdAt: now,
    listedAt: listedAt,
    soldAt: soldAt,
  );

  group('creating takes the minimum', () {
    test('an item is valid with a title and nothing else', () {
      final Item created = item(status: ItemStatus.draft);

      // Hard rule 2: no price, no photo, no category, no source.
      expect(created.purchasePrice, isNull);
      expect(created.minimumPrice, isNull);
      expect(created.photoUrls, isEmpty);
      expect(created.status, ItemStatus.draft);
    });
  });

  group('selling checks the shelf, not a price', () {
    test('an item on the shelf may be sold — the item carries no price', () {
      // Owner's rule: the item has no price of its own any more, so there is
      // nothing about it that can be missing one. What is asked for a sale is
      // typed into the sheet that records it.
      final ItemTransitionCheck result = ItemTransition.check(
        item(),
        ItemStatus.sold,
      );

      expect(result.isAllowed, isTrue);
    });

    test('is allowed once a price is set', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(askingPrice: const Money(4500, 'USD')),
        ItemStatus.sold,
      );

      expect(result.isAllowed, isTrue);
    });

    test('reports every reason at once, not the first', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(status: ItemStatus.sold, quantity: 0),
        ItemStatus.sold,
      );

      expect(
        result.blocks,
        containsAll(<ItemTransitionBlock>[
          ItemTransitionBlock.noQuantity,
          ItemTransitionBlock.wrongStatus,
        ]),
      );
    });

    test('a hand-picked sold is allowed, and empties the shelf with it', () {
      // Owner's rule: the status is editable, `sold` included. It writes no
      // order, so revenue and profit still come from Mark as sold — what it
      // records is that the stock has gone.
      final Item sold = ItemTransition.apply(
        item(askingPrice: const Money(4500, 'USD'), quantity: 3),
        ItemStatus.sold,
        now: now,
      );

      expect(sold.status, ItemStatus.sold);
      expect(sold.quantity, 0);
      expect(sold.soldAt, now);
    });
  });

  group('applying a transition', () {
    test('stamps listedAt the first time only, so staleness is measured '
        'from the original listing', () {
      final DateTime firstListing = DateTime(2026, 1, 1);
      final Item relisted = ItemTransition.apply(
        item(status: ItemStatus.inStock, listedAt: firstListing),
        ItemStatus.inStock,
        now: now,
      );

      expect(relisted.listedAt, firstListing);
    });

    test('throws rather than writing a half-valid item', () {
      expect(
        () => ItemTransition.apply(
          item(status: ItemStatus.sold, quantity: 0),
          ItemStatus.inStock,
          now: now,
        ),
        throwsStateError,
      );
    });

    test('selling one of several leaves the rest where they were', () {
      final Item listed = item(
        status: ItemStatus.inStock,
        quantity: 3,
        listedAt: now,
      );

      final Item afterSale = ItemTransition.sell(listed, now: now);

      // Two still on the shelf, so the row is not sold and its staleness
      // clock is untouched.
      expect(afterSale.quantity, 2);
      expect(afterSale.status, ItemStatus.inStock);
      expect(afterSale.soldAt, isNull);
      expect(afterSale.listedAt, now);
    });

    test('the sale that empties the shelf is the one that sells the row', () {
      final Item listed = item(status: ItemStatus.inStock, listedAt: now);

      final Item afterSale = ItemTransition.sell(listed, now: now);

      expect(afterSale.quantity, 0);
      expect(afterSale.status, ItemStatus.sold);
      expect(afterSale.soldAt, now);
      expect(afterSale.quantityOnHand, 0);
    });

    test('an empty shelf cannot be sold from', () {
      final Item soldOut = item(status: ItemStatus.sold, quantity: 0);

      expect(() => ItemTransition.sell(soldOut, now: now), throwsStateError);
    });

    test('a status move leaves the count exactly where it was', () {
      // Quantity and status are independent — owner's rule. Picking `sold`
      // used to empty the count, which is the app editing a field the seller
      // did not touch; the contradiction is drawn as a tag instead.
      final Item sold = ItemTransition.setStatus(
        item(status: ItemStatus.inStock, quantity: 4),
        ItemStatus.sold,
        now: now,
      );

      expect(sold.status, ItemStatus.sold);
      expect(sold.quantity, 4);
      expect(sold.soldAt, now);
    });

    test('going live stamps the clock instead of moving the status', () {
      final Item draft = item(status: ItemStatus.draft);

      final Item live = ItemTransition.markListed(draft, now: now);

      // A draft becomes stock the seller is selling; anything already on the
      // shelf keeps the state it had.
      expect(live.status, ItemStatus.inStock);
      expect(live.listedAt, now);
      expect(
        ItemTransition.markListed(
          item(listedAt: now.subtract(const Duration(days: 40))),
          now: now,
        ).listedAt,
        now.subtract(const Duration(days: 40)),
        reason: 'a relist must not reset the staleness clock',
      );
    });

    test('a count moves no status at all', () {
      // Not the archive, and not a sale either: only the tags the seller picks
      // and the verbs move a state.
      expect(
        item(status: ItemStatus.archived, quantity: 4).status,
        ItemStatus.archived,
      );
      expect(
        item(status: ItemStatus.sold, quantity: 4).status,
        ItemStatus.sold,
      );
    });

    test('coming back onto the shelf clears the sold date', () {
      final Item sold = item(status: ItemStatus.sold, soldAt: now);

      final Item returned = ItemTransition.apply(
        sold,
        ItemStatus.inStock,
        now: now,
      );

      // An item on hand that still carries a sold date is one every export
      // and every report reads as sold.
      expect(returned.status, ItemStatus.inStock);
      expect(returned.soldAt, isNull);
      expect(returned.quantityOnHand, 1);
    });

    test('archiving a sold item keeps the sold date — it really did sell', () {
      final Item sold = item(status: ItemStatus.sold, soldAt: now);

      final Item archived = ItemTransition.apply(
        sold,
        ItemStatus.archived,
        now: now,
      );

      expect(archived.soldAt, now);
    });

    test('archiving asks for nothing — a correction is never blocked', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(),
        ItemStatus.archived,
      );

      expect(result.isAllowed, isTrue);
    });
  });
}

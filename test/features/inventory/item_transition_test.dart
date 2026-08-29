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
    askingPrice: askingPrice,
    listedAt: listedAt,
    soldAt: soldAt,
  );

  group('creating takes the minimum', () {
    test('an item is valid with a title and nothing else', () {
      final Item created = item(status: ItemStatus.draft);

      // Hard rule 2: no price, no photo, no category, no source.
      expect(created.purchasePrice, isNull);
      expect(created.askingPrice, isNull);
      expect(created.photoUrls, isEmpty);
      expect(created.status, ItemStatus.draft);
    });
  });

  group('selling needs a sale price', () {
    test('is blocked when no asking price was entered', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(),
        ItemStatus.sold,
      );

      expect(result.isAllowed, isFalse);
      expect(result.blocks, contains(ItemTransitionBlock.missingSalePrice));
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
          ItemTransitionBlock.missingSalePrice,
        ]),
      );
    });

    test('a hand-picked sold is refused whatever else is right', () {
      // Hard rule 3: revenue and profit are read from the order, so the flag
      // is set by recording the sale, never on its own.
      final ItemTransitionCheck result = ItemTransition.manualCheck(
        item(askingPrice: const Money(4500, 'USD')),
        ItemStatus.sold,
      );

      expect(result.blocks, contains(ItemTransitionBlock.needsSaleRecord));
    });
  });

  group('applying a transition', () {
    test('stamps listedAt the first time only, so staleness is measured '
        'from the original listing', () {
      final DateTime firstListing = DateTime(2026, 1, 1);
      final Item relisted = ItemTransition.apply(
        item(
          status: ItemStatus.inStock,
          askingPrice: const Money(4500, 'USD'),
          listedAt: firstListing,
        ),
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
        askingPrice: const Money(4500, 'USD'),
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
      final Item listed = item(
        status: ItemStatus.inStock,
        askingPrice: const Money(4500, 'USD'),
        listedAt: now,
      );

      final Item afterSale = ItemTransition.sell(listed, now: now);

      expect(afterSale.quantity, 0);
      expect(afterSale.status, ItemStatus.sold);
      expect(afterSale.soldAt, now);
      expect(afterSale.quantityOnHand, 0);
    });

    test('an empty shelf cannot be sold from', () {
      final Item soldOut = item(
        status: ItemStatus.sold,
        askingPrice: const Money(4500, 'USD'),
        quantity: 0,
      );

      expect(() => ItemTransition.sell(soldOut, now: now), throwsStateError);
    });

    test('putting stock behind a sold row puts it back on the shelf', () {
      final Item restocked = ItemTransition.restocked(
        item(status: ItemStatus.sold, soldAt: now, quantity: 4),
        now: now,
      );

      expect(restocked.status, ItemStatus.inStock);
      expect(restocked.soldAt, isNull);
      expect(restocked.quantityOnHand, 4);
    });

    test('restocking adds to the count and puts the row back in stock', () {
      final Item soldOut = item(
        status: ItemStatus.sold,
        quantity: 0,
        soldAt: now,
      );

      final Item restocked = ItemTransition.restock(soldOut, 5, now: now);

      // Adds rather than replaces: the box asks how many arrived.
      expect(restocked.quantity, 5);
      expect(restocked.status, ItemStatus.inStock);
      expect(restocked.soldAt, isNull);
    });

    test('restocking an item that still has stock adds to what is there', () {
      final Item onShelf = item(quantity: 2);

      expect(ItemTransition.restock(onShelf, 3, now: now).quantity, 5);
    });

    test('restocking by nothing is refused', () {
      expect(
        () => ItemTransition.restock(item(quantity: 1), 0, now: now),
        throwsStateError,
      );
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

    test('a count does not undo an archive', () {
      // Archiving is a deliberate withdrawal; only a verb brings it back.
      final Item archived = ItemTransition.restocked(
        item(status: ItemStatus.archived, quantity: 4),
        now: now,
      );

      expect(archived.status, ItemStatus.archived);
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

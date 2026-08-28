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

  group('listing needs a price', () {
    test('is blocked when no asking price was entered', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(),
        ItemStatus.listed,
      );

      expect(result.isAllowed, isFalse);
      expect(result.blocks, contains(ItemTransitionBlock.missingPrice));
    });

    test('is allowed once a price is set', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(askingPrice: const Money(4500, 'USD')),
        ItemStatus.listed,
      );

      expect(result.isAllowed, isTrue);
    });

    test('reports every reason at once, not the first', () {
      final ItemTransitionCheck result = ItemTransition.check(
        item(status: ItemStatus.sold, quantity: 0),
        ItemStatus.listed,
      );

      expect(
        result.blocks,
        containsAll(<ItemTransitionBlock>[
          ItemTransitionBlock.noQuantity,
          ItemTransitionBlock.wrongStatus,
          ItemTransitionBlock.missingPrice,
        ]),
      );
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
        ItemStatus.listed,
        now: now,
      );

      expect(relisted.listedAt, firstListing);
    });

    test('throws rather than writing a half-valid item', () {
      expect(
        () => ItemTransition.apply(item(), ItemStatus.listed, now: now),
        throwsStateError,
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

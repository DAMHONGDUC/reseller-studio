import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';

/// The figures an item derives rather than stores (hard rule 3).
void main() {
  final DateTime created = DateTime(2026, 1, 1);
  final DateTime listed = DateTime(2026, 3, 1);
  final DateTime sold = DateTime(2026, 5, 1);

  Item itemWith({
    Money? cost,
    Money? asking,
    ItemStatus status = ItemStatus.listed,
  }) => Item(
    id: 'itm-1',
    title: 'Jacket',
    quantity: 1,
    status: status,
    createdAt: created,
    listedAt: listed,
    soldAt: sold,
    purchasePrice: cost,
    askingPrice: asking,
  );

  group('expectedMargin', () {
    test('is the profit as a share of what is being asked', () {
      final Item item = itemWith(
        cost: const Money(4500, 'USD'),
        asking: const Money(18500, 'USD'),
      );

      expect(item.expectedMargin, closeTo(0.7567, 1e-4));
    });

    test('goes negative when the asking price is under the cost', () {
      final Item item = itemWith(
        cost: const Money(12990, 'USD'),
        asking: const Money(11990, 'USD'),
      );

      expect(item.expectedMargin, lessThan(0));
    });

    test('is null when either figure is missing', () {
      // Hard rule 5: an unknown cost makes the margin unknowable, and a zero
      // would tell the seller they are keeping none of the price.
      expect(itemWith(asking: const Money(18500, 'USD')).expectedMargin, isNull);
      expect(itemWith(cost: const Money(4500, 'USD')).expectedMargin, isNull);
    });
  });

  group('stateSince', () {
    test('reads the timestamp of the state the item is in', () {
      expect(itemWith(status: ItemStatus.sold).stateSince, sold);
      expect(itemWith(status: ItemStatus.listed).stateSince, listed);
      expect(itemWith(status: ItemStatus.draft).stateSince, created);
    });

    test('falls back to creation when that timestamp was never written', () {
      // A mark-sold that failed to stamp the date must not make the row claim
      // the item has been sold since it was created — it must say something,
      // and creation is the only date every item has.
      final Item item = Item(
        id: 'itm-2',
        title: 'Jacket',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: created,
      );

      expect(item.stateSince, created);
    });
  });
}

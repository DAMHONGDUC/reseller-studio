import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';

/// The figures an item derives rather than stores (hard rule 3).
void main() {
  final DateTime created = DateTime(2026, 1, 1);
  final DateTime listed = DateTime(2026, 3, 1);
  final DateTime sold = DateTime(2026, 5, 1);

  Item itemWith({ItemStatus status = ItemStatus.listed}) => Item(
    id: 'itm-1',
    title: 'Jacket',
    quantity: 1,
    status: status,
    createdAt: created,
    listedAt: listed,
    soldAt: sold,
  );

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

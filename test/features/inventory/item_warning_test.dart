import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_warning.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_consistency.dart';

/// **A pair that cannot both be true is drawn, never refused** — owner's rule.
/// Quantity and status are edited freely and neither writes the other, so the
/// record is allowed to contradict itself; this is what notices.
void main() {
  Item item({required ItemStatus status, required int quantity}) => Item(
    id: 'itm-1',
    title: 'Jacket',
    status: status,
    quantity: quantity,
    createdAt: DateTime(2026),
  );

  test('stock on hand with nothing on the shelf is a gap', () {
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.inStock, quantity: 0)),
      <ItemWarning>[ItemWarning.emptyShelf],
    );
    // A draft counts as on hand, and an empty one makes the same claim.
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.draft, quantity: 0)),
      <ItemWarning>[ItemWarning.emptyShelf],
    );
  });

  test('sold while the count says there are some is a contradiction', () {
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.sold, quantity: 4)),
      <ItemWarning>[ItemWarning.soldWithStock],
    );
  });

  test('an archived item with stock is not a warning', () {
    // Withdrawing something is not giving it away, and the count is what the
    // seller still owns.
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.archived, quantity: 4)),
      isEmpty,
    );
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.archived, quantity: 0)),
      isEmpty,
    );
  });

  test('a record that agrees with itself says nothing', () {
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.inStock, quantity: 3)),
      isEmpty,
    );
    expect(
      ItemConsistency.warnings(item(status: ItemStatus.sold, quantity: 0)),
      isEmpty,
    );
  });
}

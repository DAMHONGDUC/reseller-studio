import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_search.dart';

/// What "this row matches what the seller typed" means (plan §21).
///
/// Inventory's list and the record-sale picker both ask it, and they have to
/// agree: a seller who finds an item by its SKU on one screen and not on the
/// other reads that as the item being gone.
void main() {
  Item item({
    String? sku,
    String? barcode,
    String title = 'Nike windbreaker',
  }) => Item(
    id: 'itm-1',
    title: title,
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: DateTime(2026, 1, 1),
    sku: sku,
    barcode: barcode,
    notes: 'Found at the Camden car boot, small mark on the left cuff',
  );

  test('an empty query matches everything', () {
    // So a caller can pass the field's raw text.
    expect(ItemSearch.matches(item(), ''), isTrue);
    expect(ItemSearch.matches(item(), '   '), isTrue);
  });

  test('the title matches on any part of it, either case', () {
    expect(ItemSearch.matches(item(), 'windbreak'), isTrue);
    expect(ItemSearch.matches(item(), 'NIKE'), isTrue);
  });

  test('the SKU and the barcode are the other two', () {
    expect(ItemSearch.matches(item(sku: 'AF-0024'), 'af-0024'), isTrue);
    expect(
      ItemSearch.matches(item(barcode: '5051234567890'), '505123'),
      isTrue,
    );
  });

  test('an item with neither is not a match for one', () {
    expect(ItemSearch.matches(item(), 'AF-0024'), isFalse);
  });

  test('notes are deliberately not searched', () {
    // They are long, and matching them makes the results look random to
    // someone who typed a SKU.
    expect(ItemSearch.matches(item(), 'Camden'), isFalse);
  });
}

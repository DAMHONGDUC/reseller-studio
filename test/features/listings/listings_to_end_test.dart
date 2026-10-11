import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_fulfilment.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/domain/services/listings_to_end.dart';

/// Delist after sale (plan §13): what is still live on an item that has gone.
void main() {
  Item item(
    String id,
    ItemStatus status, {
    ItemFulfilment fulfilment = ItemFulfilment.stocked,
  }) => Item(
    id: id,
    title: id,
    quantity: 0,
    status: status,
    createdAt: DateTime(2026, 10, 1),
    fulfilment: fulfilment,
  );
  Listing listing(String id, String itemId, ListingStatus status) => Listing(
    id: id,
    itemId: itemId,
    marketplaceId: 'ebay',
    marketplaceName: 'eBay',
    title: id,
    price: const Money(4500, 'USD'),
    status: status,
    createdAt: DateTime(2026, 10, 1),
  );

  test('a live listing of a sold or archived item is left to end', () {
    final List<Listing> toEnd = ListingsToEnd.after(
      listings: <Listing>[
        listing('a', 'sold', ListingStatus.active),
        listing('b', 'sold', ListingStatus.ended),
        listing('c', 'gone', ListingStatus.paused),
        listing('d', 'shelf', ListingStatus.active),
      ],
      items: <String, Item>{
        'sold': item('sold', ItemStatus.sold),
        'gone': item('gone', ItemStatus.archived),
        'shelf': item('shelf', ItemStatus.inStock),
      },
    );

    expect(toEnd.map((Listing l) => l.id), <String>['a', 'c']);
  });

  test('a dropshipped item never sells out, so its listings stay', () {
    expect(
      ListingsToEnd.after(
        listings: <Listing>[listing('a', 'ds', ListingStatus.active)],
        items: <String, Item>{
          'ds': item(
            'ds',
            ItemStatus.sold,
            fulfilment: ItemFulfilment.dropship,
          ),
        },
      ),
      isEmpty,
    );
  });
}

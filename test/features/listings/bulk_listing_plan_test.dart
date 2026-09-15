import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/domain/services/bulk_listing_plan.dart';

/// Listing day is a batch, and a batch action has to say what it will not do.
///
/// Of forty ticked rows some are already on eBay, some are archived and some
/// have no price to list at. A bulk action that silently did nothing to nine
/// of them would be worse than no bulk action, so the plan separates the three
/// before anything is written.
void main() {
  const String gbp = 'GBP';

  final DateTime now = DateTime(2026, 6, 1);

  Money gbpOf(int minor) => Money(minor, gbp);

  Item itemOf({
    required String id,
    ItemStatus status = ItemStatus.inStock,
    Money? expected,
    int quantity = 1,
  }) => Item(
    id: id,
    title: 'Item $id',
    quantity: quantity,
    status: status,
    createdAt: now,
    expectedPrice: expected,
  );

  Listing listingOf({required String itemId, required String on}) => Listing(
        id: 'lst-$itemId-$on',
        itemId: itemId,
        marketplaceId: on,
        marketplaceName: on,
        title: 'Item $itemId',
        price: gbpOf(4500),
        status: ListingStatus.draft,
        createdAt: now,
      );

  BulkListingPlan planFor(
    List<Item> items, {
    Set<String> on = const <String>{'ebay'},
    List<Listing> listings = const <Listing>[],
    double uplift = 0,
  }) => BulkListingPlan.from(
    items: items,
    marketplaceIds: on,
    listings: listings,
    uplift: uplift,
  );

  test('each item goes up at its own expected price', () {
    // Forty items do not share a price, so the sheet never asks for one.
    final BulkListingPlan plan = planFor(<Item>[
      itemOf(id: 'a', expected: gbpOf(4500)),
      itemOf(id: 'b', expected: gbpOf(1200)),
    ]);

    expect(plan.lines.first.prices['ebay'], gbpOf(4500));
    expect(plan.lines.last.prices['ebay'], gbpOf(1200));
    expect(plan.listingCount, 2);
  });

  test('an uplift raises every price by the same fraction', () {
    final BulkListingPlan plan = planFor(<Item>[
      itemOf(id: 'a', expected: gbpOf(4500)),
    ], uplift: 0.1);

    expect(plan.lines.single.prices['ebay'], gbpOf(4950));
  });

  test('an item with no expected price is skipped, never listed at zero', () {
    // A price is what a listing is, and null means nobody has said what this
    // is worth (hard rule 4) — not that it is free.
    final BulkListingPlan plan = planFor(<Item>[itemOf(id: 'a')]);

    expect(plan.withoutPrice.map((Item i) => i.id), <String>['a']);
    expect(plan.isEmpty, isTrue);
    expect(plan.skippedCount, 1);
  });

  test('sold and archived stock cannot be listed', () {
    final BulkListingPlan plan = planFor(<Item>[
      itemOf(id: 'a', status: ItemStatus.sold, expected: gbpOf(4500)),
      itemOf(id: 'b', status: ItemStatus.archived, expected: gbpOf(4500)),
      itemOf(id: 'c', expected: gbpOf(4500), quantity: 0),
    ]);

    expect(plan.notListable, hasLength(3));
    expect(plan.isEmpty, isTrue);
  });

  test('a platform the item is already on is left alone', () {
    final BulkListingPlan plan = planFor(
      <Item>[itemOf(id: 'a', expected: gbpOf(4500))],
      on: <String>{'ebay', 'depop'},
      listings: <Listing>[listingOf(itemId: 'a', on: 'ebay')],
    );

    // Listing it twice on the same platform is the bug this prevents.
    expect(plan.lines.single.prices.keys, <String>['depop']);
  });

  test('an item already on every platform picked is skipped, not empty', () {
    final BulkListingPlan plan = planFor(
      <Item>[itemOf(id: 'a', expected: gbpOf(4500))],
      listings: <Listing>[listingOf(itemId: 'a', on: 'ebay')],
    );

    expect(plan.alreadyListed.map((Item i) => i.id), <String>['a']);
    expect(plan.lines, isEmpty);
    expect(plan.skippedCount, 1);
  });

  test('the counts separate items from listings', () {
    // Two items on three platforms is six listings, and the sheet says both
    // numbers because they answer different questions.
    final BulkListingPlan plan = planFor(
      <Item>[
        itemOf(id: 'a', expected: gbpOf(4500)),
        itemOf(id: 'b', expected: gbpOf(4500)),
      ],
      on: <String>{'ebay', 'depop', 'etsy'},
    );

    expect(plan.itemCount, 2);
    expect(plan.listingCount, 6);
    expect(plan.skippedCount, 0);
  });
}

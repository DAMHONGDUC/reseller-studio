import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/domain/services/listing_marketplaces.dart';
import 'package:reseller_studio/features/listings/domain/services/listing_pricing.dart';
import 'package:reseller_studio/features/listings/domain/services/listings_by_item.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';

/// What "the price of a cross-listed item" means, in one place.
///
/// The item carries no price of its own, so every screen asks the listings —
/// and two of them asking it two ways is how the List screen and the reprice
/// sheet come to disagree.
void main() {
  Listing listing({
    required String id,
    required String itemId,
    required Marketplace marketplace,
    required Money price,
    ListingStatus status = ListingStatus.active,
  }) => Listing(
    id: id,
    itemId: itemId,
    marketplace: marketplace,
    title: 'A listing',
    price: price,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );

  group('sharedPrice', () {
    test('is the one price when every listing agrees', () {
      expect(
        ListingPricing.sharedPrice(<Listing>[
          listing(
            id: 'a',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(2500, 'USD'),
          ),
          listing(
            id: 'b',
            itemId: 'itm-1',
            marketplace: Marketplace.depop,
            price: const Money(2500, 'USD'),
          ),
        ]),
        const Money(2500, 'USD'),
      );
    });

    test('is null when they disagree, so nothing is pre-filled', () {
      // Pre-filling with the number that belongs to one of four platforms,
      // and then applying it to all four, is a silent reprice.
      expect(
        ListingPricing.sharedPrice(<Listing>[
          listing(
            id: 'a',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(2500, 'USD'),
          ),
          listing(
            id: 'b',
            itemId: 'itm-1',
            marketplace: Marketplace.depop,
            price: const Money(2200, 'USD'),
          ),
        ]),
        isNull,
      );
    });

    test('is null with nothing listed', () {
      expect(ListingPricing.sharedPrice(const <Listing>[]), isNull);
    });
  });

  group('byMarketplace', () {
    test('keys each price by the platform own name', () {
      final Map<String, Money> prices = ListingPricing.byMarketplace(<Listing>[
        listing(
          id: 'a',
          itemId: 'itm-1',
          marketplace: Marketplace.ebay,
          price: const Money(2500, 'USD'),
        ),
        listing(
          id: 'b',
          itemId: 'itm-1',
          marketplace: Marketplace.depop,
          price: const Money(2200, 'USD'),
        ),
      ]);

      expect(prices['ebay'], const Money(2500, 'USD'));
      expect(prices['depop'], const Money(2200, 'USD'));
    });

    test('the first listing on a platform wins', () {
      // A second listing on one platform is a repair case, and the older
      // record is what every other screen is already showing.
      expect(
        ListingPricing.byMarketplace(<Listing>[
          listing(
            id: 'a',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(2500, 'USD'),
          ),
          listing(
            id: 'b',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(1900, 'USD'),
          ),
        ])['ebay'],
        const Money(2500, 'USD'),
      );
    });
  });

  group('topPrice', () {
    test('is the highest of them', () {
      expect(
        ListingPricing.topPrice(<Listing>[
          listing(
            id: 'a',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(2500, 'USD'),
          ),
          listing(
            id: 'b',
            itemId: 'itm-1',
            marketplace: Marketplace.depop,
            price: const Money(3100, 'USD'),
          ),
        ]),
        const Money(3100, 'USD'),
      );
    });

    test('ignores a listing in another currency', () {
      // Two currencies cannot be compared (hard rule 4), so the first
      // listing's currency wins and the rest are not weighed against it.
      expect(
        ListingPricing.topPrice(<Listing>[
          listing(
            id: 'a',
            itemId: 'itm-1',
            marketplace: Marketplace.ebay,
            price: const Money(2500, 'USD'),
          ),
          listing(
            id: 'b',
            itemId: 'itm-1',
            marketplace: Marketplace.depop,
            price: const Money(9900, 'GBP'),
          ),
        ]),
        const Money(2500, 'USD'),
      );
    });

    test('is null with nothing listed', () {
      expect(ListingPricing.topPrice(const <Listing>[]), isNull);
    });
  });

  group('marketplaces an item is on', () {
    final List<Listing> all = <Listing>[
      listing(
        id: 'a',
        itemId: 'itm-1',
        marketplace: Marketplace.ebay,
        price: const Money(2500, 'USD'),
      ),
      listing(
        id: 'b',
        itemId: 'itm-1',
        marketplace: Marketplace.depop,
        price: const Money(2200, 'USD'),
        status: ListingStatus.draft,
      ),
      listing(
        id: 'c',
        itemId: 'itm-2',
        marketplace: Marketplace.ebay,
        price: const Money(800, 'USD'),
      ),
    ];

    test('a draft counts, because publishing writes drafts', () {
      // A live-only count would answer zero for every item in the app.
      expect(ListingMarketplaces.countFor(all, 'itm-1'), 2);
      expect(ListingMarketplaces.forItem(all, 'itm-1'), <Marketplace>{
        Marketplace.ebay,
        Marketplace.depop,
      });
    });

    test('an item on nothing is zero, not a missing figure', () {
      expect(ListingMarketplaces.countFor(all, 'itm-99'), 0);
    });

    test('keys are the enum own names', () {
      expect(ListingMarketplaces.keys(all), <String>{'ebay', 'depop'});
    });

    test('grouping keeps every listing under its item', () {
      final Map<String, List<Listing>> byItem = ListingsByItem.group(all);

      expect(byItem['itm-1'], hasLength(2));
      expect(byItem['itm-2'], hasLength(1));
      expect(byItem['itm-99'], isNull);
    });
  });
}

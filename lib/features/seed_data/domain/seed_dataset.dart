import '../../../core/money/money.dart';
import '../../expenses/domain/entities/expense.dart';
import '../../inventory/domain/entities/item.dart';
import '../../inventory/domain/entities/item_category.dart';
import '../../inventory/domain/entities/storage_location.dart';
import '../../inventory/domain/enums/item_status.dart';
import '../../listings/domain/entities/listing.dart';
import '../../listings/domain/enums/listing_status.dart';
import '../../offers/domain/entities/offer.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/domain/enums/order_status.dart';
import '../../sourcing/domain/entities/purchase.dart';
import '../../sourcing/domain/entities/source.dart';

/// Three rows of everything, written into a real workspace from the dev menu.
///
/// **Coherence, not volume.** Every item traces to a purchase, every purchase
/// to a source, every order to an item that existed, and the numbers add up by
/// hand — which is the whole reason it is written out rather than generated.
/// Three of each is enough for that: a screen that renders three rows renders
/// thirty, and a seeded business nobody can check by eye teaches nothing.
///
/// Five properties are deliberate. They are what the screens must handle and
/// what a tidy dataset would hide, so an edit that loses one loses the point
/// of seeding at all:
///
/// 1. **[SeedDatasetConstant.uncostedItemId] has no purchase price.** Quick
///    Add takes only a title (hard rule 2), so real inventory always holds
///    rows the seller never finished. It is what makes `—` appear, and it
///    proves hard rule 5 is honoured rather than assumed.
/// 2. **One listing is stale and one failed to publish**, so Needs Attention
///    has rows rather than being a block nobody sees populated.
/// 3. **One order sold under cost**, so the loss colour renders somewhere.
/// 4. **One order has no payout**, so Payouts has something to reconcile —
///    the app measures a fee rather than estimating it (hard rule 3), and an
///    order nobody has reconciled is work rather than a blank.
/// 5. **One expense is recurring and older than a month**, so Expenses' "Due
///    now" block has a row.
///
/// Dates are relative to a [now] passed in rather than read from the clock, so
/// a test pins it and gets byte-identical data.
class SeedDataset {
  SeedDataset._({
    required this.sources,
    required this.purchases,
    required this.items,
    required this.listings,
    required this.orders,
    required this.expenses,
    required this.categories,
    required this.locations,
    required this.offers,
  });

  /// Build the world.
  factory SeedDataset.build({required DateTime now, String currency = 'USD'}) {
    Money money(int minor) => Money(minor, currency);
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    final List<Source> sources = <Source>[
      Source(
        id: 'seed-src-1',
        name: 'Goodwill — Riverside',
        createdAt: daysAgo(400),
        type: SourceType.thriftStore,
        address: '1180 Riverside Ave',
        notes: 'Half-price tags on Tuesdays. Best for outerwear.',
      ),
      Source(
        id: 'seed-src-2',
        name: 'County Pallet Auction',
        createdAt: daysAgo(88),
        type: SourceType.auction,
        website: 'https://example.com/county-pallet',
      ),
      Source(
        id: 'seed-src-3',
        name: 'Maple St. garage sales',
        createdAt: daysAgo(40),
        type: SourceType.garageSale,
      ),
    ];

    final List<Purchase> purchases = <Purchase>[
      Purchase(
        id: 'seed-pur-1',
        purchaseDate: daysAgo(96),
        createdAt: daysAgo(96),
        sourceId: 'seed-src-1',
        totalCost: money(4200),
        notes: 'Six pieces off the winter rack.',
        itemCount: 1,
      ),
      Purchase(
        id: 'seed-pur-2',
        purchaseDate: daysAgo(41),
        createdAt: daysAgo(41),
        sourceId: 'seed-src-2',
        totalCost: money(9500),
        notes: 'Returns pallet, unmanifested.',
        itemCount: 1,
      ),
      // Bought, not yet unpacked: the row the uncosted item came off, and the
      // reason that item has no price to show.
      Purchase(
        id: 'seed-pur-3',
        purchaseDate: daysAgo(12),
        createdAt: daysAgo(12),
        sourceId: 'seed-src-3',
        totalCost: money(1800),
        itemCount: 0,
      ),
    ];

    final List<Item> items = <Item>[
      // Sold, and profitable.
      Item(
        id: 'seed-itm-1',
        title: 'Patagonia Synchilla fleece — mens L',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: daysAgo(96),
        purchasePrice: money(1200),
        purchaseId: 'seed-pur-1',
        sourceId: 'seed-src-1',
        categoryId: 'seed-cat-1',
        purchaseDate: daysAgo(96),
        sku: 'SEED-0001',
        barcode: SeedDatasetConstant.ean13Barcode,
        condition: ItemCondition.good,
        locationId: 'seed-loc-2',
        listedAt: daysAgo(92),
        soldAt: daysAgo(70),
      ),
      // Sold under cost. Resellers make bad buys; the loss colour needs a row.
      Item(
        id: 'seed-itm-2',
        title: 'Bluetooth speaker — untested, returns pallet',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: daysAgo(41),
        purchasePrice: money(3200),
        purchaseId: 'seed-pur-2',
        sourceId: 'seed-src-2',
        categoryId: 'seed-cat-3',
        purchaseDate: daysAgo(41),
        sku: 'SEED-0002',
        barcode: SeedDatasetConstant.ean8Barcode,
        condition: ItemCondition.fair,
        notes: 'Battery held 20 minutes. Sold cheap rather than eat it.',
        locationId: 'seed-loc-3',
        listedAt: daysAgo(36),
        soldAt: daysAgo(9),
      ),
      // Quick Add and never finished: no cost, no purchase, still on the
      // shelf. Every `—` in the app renders off this row.
      Item(
        id: SeedDatasetConstant.uncostedItemId,
        title: 'Vintage Levi 501 — 34x32, redline selvedge',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(96),
        expectedPrice: money(18000),
        sourceId: 'seed-src-3',
        categoryId: 'seed-cat-2',
        sku: 'SEED-0003',
        barcode: SeedDatasetConstant.upcABarcode,
        condition: ItemCondition.good,
        locationId: 'seed-loc-3',
        listedAt: daysAgo(84),
      ),
    ];

    // All three hang off the unsold item, which is the only one still on the
    // shelf — and cross-listing one item to three marketplaces is what the
    // cross-list screen is for.
    final List<Listing> listings = <Listing>[
      // Stale: published 84 days ago, past the staleness threshold.
      Listing(
        id: 'seed-lst-1',
        itemId: SeedDatasetConstant.uncostedItemId,
        marketplaceId: 'ebay',
        marketplaceName: 'eBay',
        title: "Vintage Levi's 501 Redline Selvedge Denim 34x32 USA Made",
        price: money(18500),
        status: ListingStatus.active,
        createdAt: daysAgo(84),
        publishedAt: daysAgo(84),
        externalListingId: '2856-seed-4471',
        externalUrl: 'https://example.com/ebay/2856-seed-4471',
        viewCount: 412,
        watcherCount: 19,
      ),
      Listing(
        id: 'seed-lst-2',
        itemId: SeedDatasetConstant.uncostedItemId,
        marketplaceId: 'depop',
        marketplaceName: 'Depop',
        title: 'vintage levis 501 redline selvedge 34x32',
        price: money(17500),
        status: ListingStatus.active,
        createdAt: daysAgo(80),
        publishedAt: daysAgo(80),
        viewCount: 88,
      ),
      // A publish that failed. Needs Attention exists for rows like this.
      Listing(
        id: 'seed-lst-3',
        itemId: SeedDatasetConstant.uncostedItemId,
        marketplaceId: 'etsy',
        marketplaceName: 'Etsy',
        title: 'Vintage Levi 501 Redline Selvedge 34x32',
        price: money(18000),
        status: ListingStatus.error,
        createdAt: daysAgo(6),
        lastError: 'Category attributes missing: Size Type',
      ),
    ];

    final List<Order> orders = <Order>[
      Order(
        id: 'seed-ord-1',
        status: OrderStatus.delivered,
        marketplaceRecordId: 'ebay',
        marketplaceNameSnapshot: 'eBay',
        salePrice: money(6800),
        shippingCost: money(1240),
        payout: money(4659),
        orderedAt: daysAgo(70),
        shippedAt: daysAgo(69),
        deliveredAt: daysAgo(65),
        buyerName: 'm.hollis',
        externalOrderId: '11-12874-59921',
        trackingNumber: '9400111899223817462',
        carrier: 'USPS',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'seed-itm-1',
            title: 'Patagonia Synchilla fleece — mens L',
            quantity: 1,
            unitPrice: money(6800),
            unitCost: money(1200),
          ),
        ],
      ),
      // Sold for less than it cost.
      Order(
        id: 'seed-ord-2',
        status: OrderStatus.delivered,
        marketplaceRecordId: 'mercari',
        marketplaceNameSnapshot: 'Mercari',
        salePrice: money(2400),
        shippingCost: money(980),
        payout: money(1876),
        orderedAt: daysAgo(9),
        shippedAt: daysAgo(8),
        deliveredAt: daysAgo(4),
        buyerName: 'd.okafor',
        externalOrderId: 'MERC-5518902',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'seed-itm-2',
            title: 'Bluetooth speaker — untested, returns pallet',
            quantity: 1,
            unitPrice: money(2400),
            unitCost: money(3200),
          ),
        ],
      ),
      // Paid and waiting to ship, so nothing has been paid out yet. Payouts
      // is where this becomes work rather than a blank (hard rule 3).
      Order(
        id: SeedDatasetConstant.unpaidOrderId,
        status: OrderStatus.toShip,
        marketplaceRecordId: 'depop',
        marketplaceNameSnapshot: 'Depop',
        salePrice: money(17500),
        orderedAt: daysAgo(1),
        shipByDate: now.add(const Duration(days: 1)),
        buyerName: 'k.nguyen',
        externalOrderId: 'DEPOP-7741',
        lines: <OrderLine>[
          OrderLine(
            itemId: SeedDatasetConstant.uncostedItemId,
            title: 'Vintage Levi 501 — 34x32, redline selvedge',
            quantity: 1,
            unitPrice: money(17500),
          ),
        ],
      ),
    ];

    final List<Expense> expenses = <Expense>[
      Expense(
        id: 'seed-exp-1',
        category: ExpenseCategory.packaging,
        amount: money(3400),
        date: daysAgo(60),
        createdAt: daysAgo(60),
        vendor: 'Uline',
        notes: 'Poly mailers, 200ct.',
      ),
      // Older than a month on purpose: it is what puts a row in Expenses'
      // "Due now" block.
      Expense(
        id: 'seed-exp-2',
        category: ExpenseCategory.software,
        amount: money(2999),
        date: daysAgo(45),
        createdAt: daysAgo(45),
        vendor: 'Listing tool',
        isRecurring: true,
      ),
      Expense(
        id: 'seed-exp-3',
        category: ExpenseCategory.shipping,
        amount: money(1240),
        date: daysAgo(69),
        createdAt: daysAgo(69),
        vendor: 'USPS',
        orderId: 'seed-ord-1',
      ),
    ];

    final List<ItemCategory> categories = <ItemCategory>[
      ItemCategory(
        id: 'seed-cat-1',
        name: 'Outerwear',
        createdAt: daysAgo(400),
      ),
      ItemCategory(id: 'seed-cat-2', name: 'Denim', createdAt: daysAgo(400)),
      ItemCategory(
        id: 'seed-cat-3',
        name: 'Electronics',
        createdAt: daysAgo(88),
      ),
    ];

    // Nested one inside the next, so the location picker is exercised at more
    // than one level.
    final List<StorageLocation> locations = <StorageLocation>[
      StorageLocation(
        id: 'seed-loc-1',
        name: 'Garage',
        kind: LocationKind.warehouse,
        createdAt: daysAgo(400),
        address: 'Home',
      ),
      StorageLocation(
        id: 'seed-loc-2',
        name: 'Shelf A',
        kind: LocationKind.shelf,
        parentId: 'seed-loc-1',
        createdAt: daysAgo(400),
      ),
      StorageLocation(
        id: 'seed-loc-3',
        name: 'Bin A1',
        kind: LocationKind.bin,
        parentId: 'seed-loc-2',
        createdAt: daysAgo(400),
        barcode: 'SEED-BIN-A1',
      ),
    ];

    // An expiring offer is the most time-sensitive thing in the app, so two
    // are pending: one lowball worth declining, one close enough to accept.
    final List<Offer> offers = <Offer>[
      Offer(
        id: 'seed-off-1',
        itemId: SeedDatasetConstant.uncostedItemId,
        itemTitle: 'Vintage Levi 501 — 34x32, redline selvedge',
        marketplaceId: 'ebay',
        marketplaceName: 'eBay',
        amount: money(16500),
        status: OfferStatus.pending,
        createdAt: daysAgo(1),
        expiresAt: now.add(const Duration(hours: 20)),
        buyerName: 'thrift_hunter_88',
        message: 'Would you take this?',
      ),
      Offer(
        id: 'seed-off-2',
        itemId: SeedDatasetConstant.uncostedItemId,
        itemTitle: 'Vintage Levi 501 — 34x32, redline selvedge',
        marketplaceId: 'depop',
        marketplaceName: 'Depop',
        amount: money(9000),
        status: OfferStatus.pending,
        createdAt: daysAgo(3),
        expiresAt: now.add(const Duration(days: 2)),
        buyerName: 'lowball_larry',
      ),
      Offer(
        id: 'seed-off-3',
        itemId: 'seed-itm-1',
        itemTitle: 'Patagonia Synchilla fleece — mens L',
        marketplaceId: 'ebay',
        marketplaceName: 'eBay',
        amount: money(1500),
        status: OfferStatus.declined,
        createdAt: daysAgo(12),
        respondedAt: daysAgo(12),
      ),
    ];

    return SeedDataset._(
      sources: sources,
      purchases: purchases,
      items: items,
      listings: listings,
      orders: orders,
      expenses: expenses,
      categories: categories,
      locations: locations,
      offers: offers,
    );
  }

  final List<Source> sources;
  final List<Purchase> purchases;
  final List<Item> items;
  final List<Listing> listings;
  final List<Order> orders;
  final List<Expense> expenses;
  final List<ItemCategory> categories;
  final List<StorageLocation> locations;
  final List<Offer> offers;

  /// Every row the seed writes, in the order it writes them.
  int get documentCount =>
      categories.length +
      locations.length +
      sources.length +
      purchases.length +
      items.length +
      listings.length +
      orders.length +
      offers.length +
      expenses.length;
}

/// The ids a caller outside the seed needs to name.
///
/// Only the two rows that carry a property a test asserts on are here: the
/// rest are an implementation detail of the dataset and nothing should reach
/// for them.
final class SeedDatasetConstant {
  /// The Quick Add row with no cost — where `—` comes from (hard rule 5).
  static const String uncostedItemId = 'seed-itm-3';

  /// The order with no payout recorded — what Payouts has to reconcile.
  static const String unpaidOrderId = 'seed-ord-3';

  // The sample bottle labels in `test/support/fixtures/sample_bottles/` carry
  // these, so scanning one on a seeded device finds a row.

  /// On the sold fleece.
  static const String ean13Barcode = '5901234123457';

  /// On the sold speaker.
  static const String ean8Barcode = '96385074';

  /// On the in-stock Levi's, so a scan lands where every action applies —
  /// and it is the format iOS reads with an extra leading zero.
  static const String upcABarcode = '036000291452';
}

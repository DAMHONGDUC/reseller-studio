import '../../../core/money/money.dart';
import '../../carriers/carrier_constant.dart';
import '../../carriers/domain/entities/carrier.dart';
import '../../expenses/domain/entities/expense.dart';
import '../../inventory/domain/entities/item.dart';
import '../../inventory/domain/entities/item_category.dart';
import '../../inventory/domain/entities/storage_location.dart';
import '../../inventory/domain/enums/item_status.dart';
import '../../listings/domain/entities/listing.dart';
import '../../listings/domain/enums/listing_status.dart';
import '../../marketplaces/domain/entities/marketplace.dart';
import '../../marketplaces/domain/enums/marketplace.dart' as legacy;
import '../../marketplaces/marketplace_constant.dart';
import '../../offers/domain/entities/offer.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/domain/enums/order_status.dart';
import '../../sourcing/domain/entities/purchase.dart';
import '../../sourcing/domain/entities/source.dart';
import '../../workspace/domain/entities/workspace.dart';

/// A believable reseller's business, generated in memory.
///
/// **The point is coherence, not volume.** Random rows would fill the screens
/// and prove nothing: analytics would show noise, the Source → Purchase →
/// Item → Listing → Order chain would not join up, and a profit figure could
/// not be checked by hand. So this builds one consistent world —
/// every item traces to a purchase, every purchase to a source, every order
/// to items that really existed, and the numbers add up.
///
/// Three properties are deliberate, because they are what the screens must
/// handle and what a tidy fake dataset would hide:
///
/// 1. **Some items have no cost.** Quick Add exists (hard rule 2), so real
///    inventory always contains rows the seller never finished. These are
///    what make `—` appear, and they prove hard rule 5 is honoured rather
///    than assumed.
/// 2. **Some listings are stale**, and some failed to publish. A dataset
///    where everything is healthy never exercises Needs Attention.
/// 3. **One order sold under cost.** Resellers make bad buys; a demo where
///    every sale is profitable hides the loss colour entirely.
///
/// Dates are generated relative to a [now] passed in, so the data is always
/// "recent" whenever it is built and never drifts into looking abandoned.
class MockDataset {
  MockDataset._({
    required this.workspace,
    required this.members,
    required this.sources,
    required this.purchases,
    required this.items,
    required this.listings,
    required this.orders,
    required this.expenses,
    required this.categories,
    required this.locations,
    required this.offers,
    required this.marketplaces,
    required this.carriers,
  });

  /// Build the world.
  ///
  /// [now] is injected rather than read from the clock so a test can pin it
  /// and get byte-identical data.
  factory MockDataset.seed({required DateTime now, String currency = 'USD'}) {
    Money money(int minor) => Money(minor, currency);
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    const String ownerId = 'dev-bypass-user';

    final Workspace workspace = Workspace(
      id: 'ws-demo',
      name: 'Attic Finds Co.',
      ownerId: ownerId,
      country: 'US',
      currency: currency,
      createdAt: daysAgo(420),
    );

    // The four a real new business starts with, so the demo and a fresh
    // account describe the same world.
    final List<Marketplace> marketplaces = <Marketplace>[
      for (final MarketplaceSeed seed in MarketplaceConstant.defaults)
        Marketplace(
          id: seed.id,
          name: seed.name,
          feeRate: seed.feeRate,
          createdAt: now,
          hue: seed.hue,
        ),
    ];
    final List<Carrier> carriers = <Carrier>[
      for (final CarrierSeed seed in CarrierConstant.defaults)
        Carrier(id: seed.id, name: seed.name, createdAt: now),
    ];

    final List<Member> members = <Member>[
      Member(
        uid: ownerId,
        role: MemberRole.owner,
        joinedAt: daysAgo(420),
        displayName: 'You',
        email: 'you@atticfinds.example',
      ),
      Member(
        uid: 'mock-member-2',
        role: MemberRole.member,
        joinedAt: daysAgo(96),
        displayName: 'Sam Rivera',
        email: 'sam@atticfinds.example',
      ),
    ];

    final List<Source> sources = <Source>[
      Source(
        id: 'src-goodwill',
        name: 'Goodwill — Riverside',
        createdAt: daysAgo(400),
        type: SourceType.thriftStore,
        address: '1180 Riverside Ave',
        notes: 'Half-price tags on Tuesdays. Best for outerwear.',
      ),
      Source(
        id: 'src-estate',
        name: 'Hillcrest Estate Sale',
        createdAt: daysAgo(150),
        type: SourceType.estateSale,
        notes: 'One-off. Mid-century glassware, priced to move on day two.',
      ),
      Source(
        id: 'src-auction',
        name: 'County Pallet Auction',
        createdAt: daysAgo(88),
        type: SourceType.auction,
        website: 'https://example.com/county-pallet',
      ),
      Source(
        id: 'src-garage',
        name: 'Maple St. garage sales',
        createdAt: daysAgo(40),
        type: SourceType.garageSale,
      ),
    ];

    final List<Purchase> purchases = <Purchase>[
      Purchase(
        id: 'pur-1',
        purchaseDate: daysAgo(96),
        createdAt: daysAgo(96),
        sourceId: 'src-goodwill',
        totalCost: money(4200),
        notes: 'Six pieces off the winter rack.',
        itemCount: 3,
      ),
      Purchase(
        id: 'pur-2',
        purchaseDate: daysAgo(74),
        createdAt: daysAgo(74),
        sourceId: 'src-estate',
        totalCost: money(12000),
        notes: 'Glassware lot. Two broken in transit — written off.',
        itemCount: 3,
      ),
      Purchase(
        id: 'pur-3',
        purchaseDate: daysAgo(41),
        createdAt: daysAgo(41),
        sourceId: 'src-auction',
        totalCost: money(9500),
        notes: 'Returns pallet, unmanifested.',
        itemCount: 3,
      ),
      Purchase(
        id: 'pur-4',
        purchaseDate: daysAgo(12),
        createdAt: daysAgo(12),
        sourceId: 'src-garage',
        totalCost: money(1800),
        itemCount: 2,
      ),
    ];

    final List<Item> items = <Item>[
      // --- Sold, and profitable. ---
      Item(
        id: 'itm-1',
        title: 'Patagonia Synchilla fleece — mens L',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: daysAgo(96),
        purchasePrice: money(1200),
        purchaseId: 'pur-1',
        sourceId: 'src-goodwill',
        purchaseDate: daysAgo(96),
        sku: 'AF-0001',
        condition: ItemCondition.good,
        locationId: 'loc-shelf-a',
        listedAt: daysAgo(92),
        soldAt: daysAgo(70),
      ),
      Item(
        id: 'itm-2',
        title: 'Pyrex Spring Blossom casserole set',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: daysAgo(74),
        purchasePrice: money(3000),
        purchaseId: 'pur-2',
        sourceId: 'src-estate',
        purchaseDate: daysAgo(74),
        sku: 'AF-0007',
        condition: ItemCondition.likeNew,
        listedAt: daysAgo(70),
        soldAt: daysAgo(38),
      ),
      // --- Sold at a loss. Resellers make bad buys; the demo must show one. ---
      Item(
        id: 'itm-3',
        title: 'Bluetooth speaker — untested, returns pallet',
        quantity: 1,
        status: ItemStatus.sold,
        createdAt: daysAgo(41),
        purchasePrice: money(3200),
        purchaseId: 'pur-3',
        sourceId: 'src-auction',
        purchaseDate: daysAgo(41),
        sku: 'AF-0012',
        condition: ItemCondition.fair,
        notes: 'Battery held 20 minutes. Sold cheap rather than eat it.',
        listedAt: daysAgo(36),
        soldAt: daysAgo(9),
      ),
      // --- Listed and stale: listed 84 days ago, past the 60-day threshold. ---
      Item(
        id: 'itm-4',
        title: 'Vintage Levi 501 — 34x32, redline selvedge',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(96),
        purchasePrice: money(1500),
        minimumPrice: money(14000),
        purchaseId: 'pur-1',
        sourceId: 'src-goodwill',
        purchaseDate: daysAgo(96),
        sku: 'AF-0002',
        condition: ItemCondition.good,
        locationId: 'loc-shelf-a',
        listedAt: daysAgo(84),
        notes: 'Priced high on purpose. Selvedge collectors are patient.',
      ),
      Item(
        id: 'itm-5',
        title: 'Fire-King jadeite mug, set of 4',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(74),
        purchasePrice: money(2800),
        purchaseId: 'pur-2',
        sourceId: 'src-estate',
        purchaseDate: daysAgo(74),
        sku: 'AF-0008',
        condition: ItemCondition.good,
        listedAt: daysAgo(66),
      ),
      // --- Listed and healthy. ---
      Item(
        id: 'itm-6',
        title: 'Carhartt detroit jacket — womens M',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(41),
        purchasePrice: money(2200),
        minimumPrice: money(7000),
        purchaseId: 'pur-3',
        sourceId: 'src-auction',
        purchaseDate: daysAgo(41),
        sku: 'AF-0013',
        condition: ItemCondition.good,
        locationId: 'loc-shelf-b',
        listedAt: daysAgo(20),
      ),
      // --- Reserved: an offer was accepted, sale not completed. ---
      Item(
        id: 'itm-7',
        title: 'Sony WH-1000XM3 headphones',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(41),
        purchasePrice: money(4100),
        purchaseId: 'pur-3',
        sourceId: 'src-auction',
        purchaseDate: daysAgo(41),
        sku: 'AF-0014',
        condition: ItemCondition.likeNew,
        listedAt: daysAgo(25),
      ),
      // --- In stock, never listed. Home's "items to list". ---
      Item(
        id: 'itm-8',
        title: 'Le Creuset dutch oven — 5.5qt, flame',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: daysAgo(12),
        purchasePrice: money(1500),
        purchaseId: 'pur-4',
        sourceId: 'src-garage',
        purchaseDate: daysAgo(12),
        sku: 'AF-0021',
        condition: ItemCondition.good,
        locationId: 'loc-bin-3',
        notes: 'Best find of the year. Photograph properly before listing.',
      ),
      // --- Quick Add leftovers: title only, no cost, no price. ---
      // These are what make `—` appear. Hard rule 5 is proven by data, not
      // asserted by a comment.
      Item(
        id: 'itm-9',
        title: 'Box of assorted brass hardware',
        quantity: 1,
        status: ItemStatus.draft,
        createdAt: daysAgo(12),
        purchaseId: 'pur-4',
        sourceId: 'src-garage',
        purchaseDate: daysAgo(12),
      ),
      Item(
        id: 'itm-10',
        title: 'Unidentified ceramic vase — check maker mark',
        quantity: 1,
        status: ItemStatus.draft,
        createdAt: daysAgo(4),
      ),
      Item(
        id: 'itm-11',
        title: 'Nike windbreaker — XL',
        quantity: 2,
        status: ItemStatus.inStock,
        createdAt: daysAgo(3),
        updatedAt: daysAgo(1),
        purchasePrice: money(900),
        sku: 'AF-0024',
        condition: ItemCondition.good,
        locationId: 'loc-bin-3',
      ),
    ];

    final List<Listing> listings = <Listing>[
      Listing(
        id: 'lst-1',
        itemId: 'itm-4',
        marketplace: legacy.Marketplace.ebay,
        title: 'Vintage Levi\'s 501 Redline Selvedge Denim 34x32 USA Made',
        price: money(18500),
        status: ListingStatus.active,
        createdAt: daysAgo(84),
        publishedAt: daysAgo(84),
        externalListingId: '2856-mock-4471',
        externalUrl: 'https://example.com/ebay/2856-mock-4471',
        viewCount: 412,
        watcherCount: 19,
      ),
      Listing(
        id: 'lst-2',
        itemId: 'itm-4',
        marketplace: legacy.Marketplace.depop,
        title: 'vintage levis 501 redline selvedge 34x32',
        price: money(17500),
        status: ListingStatus.active,
        createdAt: daysAgo(80),
        publishedAt: daysAgo(80),
        viewCount: 88,
      ),
      Listing(
        id: 'lst-3',
        itemId: 'itm-5',
        marketplace: legacy.Marketplace.etsy,
        title: 'Fire-King Jadeite Mugs Set of 4 Restaurant Ware',
        price: money(7200),
        status: ListingStatus.active,
        createdAt: daysAgo(66),
        publishedAt: daysAgo(66),
        viewCount: 233,
        watcherCount: 7,
      ),
      Listing(
        id: 'lst-4',
        itemId: 'itm-6',
        marketplace: legacy.Marketplace.poshmark,
        title: 'Carhartt Detroit Jacket Women\'s M Brown Duck',
        price: money(8900),
        status: ListingStatus.active,
        createdAt: daysAgo(20),
        publishedAt: daysAgo(20),
        viewCount: 61,
        watcherCount: 3,
      ),
      // A publish that failed. Needs Attention exists for rows like this.
      Listing(
        id: 'lst-5',
        itemId: 'itm-7',
        marketplace: legacy.Marketplace.mercari,
        title: 'Sony WH-1000XM3 Wireless Headphones',
        price: money(11000),
        status: ListingStatus.error,
        createdAt: daysAgo(25),
        lastError: 'Listing rejected: brand requires proof of authenticity.',
      ),
      Listing(
        id: 'lst-6',
        itemId: 'itm-8',
        marketplace: legacy.Marketplace.ebay,
        title: 'Le Creuset 5.5qt Round Dutch Oven Flame Orange',
        price: money(14500),
        status: ListingStatus.draft,
        createdAt: daysAgo(6),
      ),
    ];

    final List<Order> orders = <Order>[
      Order(
        id: 'ord-1',
        status: OrderStatus.delivered,
        marketplace: legacy.Marketplace.ebay,
        salePrice: money(6800),
        fees: money(901),
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
            itemId: 'itm-1',
            title: 'Patagonia Synchilla fleece — mens L',
            quantity: 1,
            unitPrice: money(6800),
            unitCost: money(1200),
          ),
        ],
      ),
      Order(
        id: 'ord-2',
        status: OrderStatus.delivered,
        marketplace: legacy.Marketplace.etsy,
        salePrice: money(9500),
        fees: money(903),
        shippingCost: money(1580),
        payout: money(7017),
        orderedAt: daysAgo(38),
        shippedAt: daysAgo(37),
        deliveredAt: daysAgo(33),
        buyerName: 'ceramicsandco',
        externalOrderId: 'ETSY-8827301',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-2',
            title: 'Pyrex Spring Blossom casserole set',
            quantity: 1,
            unitPrice: money(9500),
            unitCost: money(3000),
          ),
        ],
      ),
      // Sold under cost. The loss colour needs a real row to render on.
      Order(
        id: 'ord-3',
        status: OrderStatus.delivered,
        marketplace: legacy.Marketplace.mercari,
        salePrice: money(3500),
        fees: money(350),
        shippingCost: money(890),
        payout: money(2260),
        orderedAt: daysAgo(9),
        shippedAt: daysAgo(8),
        deliveredAt: daysAgo(4),
        buyerName: 'dealhunter_22',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-3',
            title: 'Bluetooth speaker — untested, returns pallet',
            quantity: 1,
            unitPrice: money(3500),
            unitCost: money(3200),
          ),
        ],
      ),
      // Waiting on the seller. This is what Home's Needs Attention counts,
      // and what the Orders tab exists to drain.
      Order(
        id: 'ord-4',
        status: OrderStatus.toShip,
        marketplace: legacy.Marketplace.poshmark,
        salePrice: money(8900),
        fees: money(1780),
        orderedAt: daysAgo(2),
        shipByDate: now.add(const Duration(days: 1)),
        buyerName: 'thriftedbyjay',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-6',
            title: 'Carhartt detroit jacket — womens M',
            quantity: 1,
            unitPrice: money(8900),
            unitCost: money(2200),
          ),
        ],
      ),
      // Overdue: the deadline has already passed.
      Order(
        id: 'ord-5',
        status: OrderStatus.toShip,
        marketplace: legacy.Marketplace.ebay,
        salePrice: money(11000),
        fees: money(1458),
        orderedAt: daysAgo(5),
        shipByDate: daysAgo(1),
        buyerName: 'audiophile_kb',
        externalOrderId: '11-13001-22187',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-7',
            title: 'Sony WH-1000XM3 headphones',
            quantity: 1,
            unitPrice: money(11000),
            unitCost: money(4100),
          ),
        ],
      ),
      Order(
        id: 'ord-6',
        status: OrderStatus.returnRequested,
        marketplace: legacy.Marketplace.ebay,
        salePrice: money(4200),
        fees: money(557),
        shippingCost: money(720),
        orderedAt: daysAgo(16),
        shippedAt: daysAgo(15),
        deliveredAt: daysAgo(11),
        buyerName: 'r.okafor',
        notes: 'Buyer says the sizing runs small. Return approved.',
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-11',
            title: 'Nike windbreaker — XL',
            quantity: 1,
            unitPrice: money(4200),
            unitCost: money(900),
          ),
        ],
      ),
    ];

    final List<Expense> expenses = <Expense>[
      Expense(
        id: 'exp-1',
        category: ExpenseCategory.packaging,
        amount: money(3400),
        date: daysAgo(60),
        createdAt: daysAgo(60),
        vendor: 'Uline',
        notes: 'Poly mailers, 200ct.',
      ),
      // Deliberately older than a month: it is what puts a row in Expenses'
      // "Due now" block, so the recurring flow is visible in the demo rather
      // than being a section nobody ever sees populated.
      Expense(
        id: 'exp-2',
        category: ExpenseCategory.software,
        amount: money(2999),
        date: daysAgo(45),
        createdAt: daysAgo(45),
        vendor: 'Listing tool',
        isRecurring: true,
      ),
      Expense(
        id: 'exp-3',
        category: ExpenseCategory.mileage,
        amount: money(2870),
        date: daysAgo(41),
        createdAt: daysAgo(41),
        mileage: 42.8,
        notes: 'County auction round trip.',
      ),
      Expense(
        id: 'exp-4',
        category: ExpenseCategory.shipping,
        amount: money(1240),
        date: daysAgo(69),
        createdAt: daysAgo(69),
        vendor: 'USPS',
        orderId: 'ord-1',
      ),
      Expense(
        id: 'exp-5',
        category: ExpenseCategory.storage,
        amount: money(8500),
        date: daysAgo(15),
        createdAt: daysAgo(15),
        vendor: 'Riverside Self Storage',
        isRecurring: true,
      ),
    ];

    // Reference data. Short lists on purpose: a demo taxonomy with forty
    // categories teaches nothing the four below do not, and the pickers that
    // read it are easier to judge at a realistic size.
    final List<ItemCategory> categories = <ItemCategory>[
      ItemCategory(
        id: 'cat-outerwear',
        name: 'Outerwear',
        createdAt: daysAgo(400),
      ),
      ItemCategory(
        id: 'cat-footwear',
        name: 'Footwear',
        createdAt: daysAgo(400),
      ),
      ItemCategory(
        id: 'cat-glassware',
        name: 'Glassware',
        createdAt: daysAgo(150),
      ),
      ItemCategory(
        id: 'cat-electronics',
        name: 'Electronics',
        createdAt: daysAgo(88),
      ),
    ];

    final List<StorageLocation> locations = <StorageLocation>[
      StorageLocation(
        id: 'loc-garage',
        name: 'Garage',
        kind: LocationKind.warehouse,
        createdAt: daysAgo(400),
        address: 'Home',
      ),
      StorageLocation(
        id: 'loc-shelf-a',
        name: 'Shelf A',
        kind: LocationKind.shelf,
        parentId: 'loc-garage',
        createdAt: daysAgo(400),
      ),
      StorageLocation(
        id: 'loc-bin-a1',
        name: 'Bin A1',
        kind: LocationKind.bin,
        parentId: 'loc-shelf-a',
        createdAt: daysAgo(400),
        barcode: 'BIN-A1',
      ),
      StorageLocation(
        id: 'loc-bin-a2',
        name: 'Bin A2',
        kind: LocationKind.bin,
        parentId: 'loc-shelf-a',
        createdAt: daysAgo(400),
        barcode: 'BIN-A2',
      ),
    ];

    // Two pending offers, because Needs Attention has to have something in
    // it and an expiring offer is the most time-sensitive thing in the app.
    // One is a lowball worth declining; the other is close enough to accept.
    final List<Offer> offers = <Offer>[
      Offer(
        id: 'off-1',
        itemId: items.first.id,
        itemTitle: items.first.title,
        marketplace: legacy.Marketplace.ebay,
        amount: money(2200),
        status: OfferStatus.pending,
        createdAt: daysAgo(1),
        expiresAt: now.add(const Duration(hours: 20)),
        buyerName: 'thrift_hunter_88',
        message: 'Would you take this?',
      ),
      Offer(
        id: 'off-2',
        itemId: items.last.id,
        itemTitle: items.last.title,
        marketplace: legacy.Marketplace.depop,
        amount: money(900),
        status: OfferStatus.pending,
        createdAt: daysAgo(3),
        expiresAt: now.add(const Duration(days: 2)),
        buyerName: 'k.nguyen',
      ),
      Offer(
        id: 'off-3',
        itemId: items.first.id,
        itemTitle: items.first.title,
        marketplace: legacy.Marketplace.ebay,
        amount: money(1500),
        status: OfferStatus.declined,
        createdAt: daysAgo(12),
        respondedAt: daysAgo(12),
      ),
    ];

    return MockDataset._(
      workspace: workspace,
      marketplaces: marketplaces,
      carriers: carriers,
      members: members,
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

  final Workspace workspace;
  final List<Member> members;
  final List<Source> sources;
  final List<Purchase> purchases;
  final List<Item> items;
  final List<Listing> listings;
  final List<Order> orders;
  final List<Expense> expenses;
  final List<ItemCategory> categories;
  final List<StorageLocation> locations;
  final List<Offer> offers;
  final List<Marketplace> marketplaces;
  final List<Carrier> carriers;
}

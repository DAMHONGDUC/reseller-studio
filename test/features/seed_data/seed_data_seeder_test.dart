import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/seed_data/domain/seed_dataset.dart';
import 'package:reseller_studio/features/seed_data/domain/services/seed_data_seeder.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// **The seeder has to write every collection, and twice must equal once.**
///
/// It is what a developer fills a real workspace from, and it is the only
/// thing that drives every live write path in one run — so a collection it
/// silently skips is a screen that is empty in front of an audience, and a row
/// it duplicates is a business whose totals stop adding up.
///
/// Run against the in-memory repositories rather than Firestore: the seeder
/// only knows the domain interfaces, so this pins its contract without a
/// backend. What it cannot prove is that Firestore accepts the documents —
/// that needs a real project.
void main() {
  late SeedDataset seed;
  late MockStore store;
  late SeedDataSeeder seeder;

  setUp(() {
    seed = SeedDataset.build(now: testNow);
    // Emptied rather than constructed empty: the store's dataset is only
    // scaffolding here, and a public "empty" factory would exist for this
    // test alone.
    store = MockStore(MockDataset.seed(now: testNow))
      ..items.clear()
      ..listings.clear()
      ..orders.clear()
      ..offers.clear()
      ..expenses.clear()
      ..categories.clear()
      ..locations.clear()
      ..sources.clear()
      ..purchases.clear();

    addTearDown(store.dispose);

    seeder = SeedDataSeeder(
      purge: InMemoryWorkspacePurgeRepository(store),
      items: InMemoryItemRepository(store),
      listings: InMemoryListingRepository(store),
      orders: InMemoryOrderRepository(store),
      offers: InMemoryOfferRepository(store),
      expenses: InMemoryExpenseRepository(store),
      categories: InMemoryCategoryRepository(store),
      locations: InMemoryLocationRepository(store),
      sources: InMemorySourceRepository(store),
      purchases: InMemoryPurchaseRepository(store),
    );
  });

  test('is three of everything', () {
    // Owner's rule, and the whole size of the seed. A collection that grows
    // past three is one nobody can check by eye any more.
    expect(<int>[
      seed.items.length,
      seed.orders.length,
      seed.listings.length,
      seed.offers.length,
      seed.expenses.length,
      seed.categories.length,
      seed.locations.length,
      seed.sources.length,
      seed.purchases.length,
    ], everyElement(3));
  });

  test('fills every collection of an empty business', () async {
    final int written = await seeder.seed(seed);

    expect(store.items, hasLength(seed.items.length));
    expect(store.listings, hasLength(seed.listings.length));
    expect(store.orders, hasLength(seed.orders.length));
    expect(store.offers, hasLength(seed.offers.length));
    expect(store.expenses, hasLength(seed.expenses.length));
    expect(store.categories, hasLength(seed.categories.length));
    expect(store.locations, hasLength(seed.locations.length));
    expect(store.sources, hasLength(seed.sources.length));
    expect(store.purchases, hasLength(seed.purchases.length));
    expect(written, seed.documentCount);
  });

  test('seeding twice replaces rather than doubles', () async {
    final int first = await seeder.seed(seed);
    final int second = await seeder.seed(seed);

    expect(second, first);
    expect(store.items, hasLength(seed.items.length));
    expect(store.orders, hasLength(seed.orders.length));
  });

  test('empties the workspace first, so nothing else survives', () async {
    // Owner's rule. Upserting on the seed's own ids replaces the seeded rows
    // and leaves every other one behind, which is a business whose totals no
    // longer match the dataset they are supposed to be checkable against.
    store.items.add(
      Item(
        id: 'not-from-the-seed',
        title: 'Typed in by hand',
        quantity: 1,
        status: ItemStatus.draft,
        createdAt: testNow,
      ),
    );

    await seeder.seed(seed);

    expect(store.items, hasLength(seed.items.length));
    expect(
      store.items.where((Item item) => item.id == 'not-from-the-seed'),
      isEmpty,
    );
  });

  test('keeps the dates the seed placed, so it looks lived-in', () async {
    await seeder.seed(seed);

    final Item seeded = seed.items.firstWhere(
      (Item item) => item.listedAt != null,
    );
    final Item stored = store.items.firstWhere(
      (Item item) => item.id == seeded.id,
    );

    // A row stamped "now" on the way in would empty Home's Needs Attention
    // block, which is the screen worth looking at.
    expect(stored.listedAt, seeded.listedAt);
    expect(stored.createdAt, seeded.createdAt);
  });

  test('keeps the two rows the screens are judged on', () {
    // Hard rule 5 needs an item with no cost to render `—` off, and hard rule
    // 3 needs an order with no payout for Payouts to have work in it. A seed
    // where everything is filled in exercises neither.
    final Item uncosted = seed.items.firstWhere(
      (Item item) => item.id == SeedDatasetConstant.uncostedItemId,
    );
    final Order unpaid = seed.orders.firstWhere(
      (Order order) => order.id == SeedDatasetConstant.unpaidOrderId,
    );

    expect(uncosted.purchasePrice, isNull);
    expect(unpaid.payout, isNull);
  });

  test('no pending offer sits on something already sold', () {
    // An offer on a sold item is a Needs Attention row the app then refuses
    // to accept — the one shape of demo data that argues against the product
    // it is demonstrating.
    for (final Offer offer in seed.offers) {
      if (offer.status != OfferStatus.pending) continue;

      final Item item = seed.items.firstWhere(
        (Item row) => row.id == offer.itemId,
        orElse: () => throw StateError('${offer.id} names a missing item'),
      );

      expect(
        item.status,
        isNot(ItemStatus.sold),
        reason: '${offer.id} is on an item the seed also marks sold',
      );
      expect(
        item.quantity,
        greaterThan(0),
        reason: '${offer.id} has none left',
      );
    }
  });
}

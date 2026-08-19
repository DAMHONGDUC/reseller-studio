import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/inventory/domain/entities/item.dart';
import 'package:seller_os/features/mock_data/data/in_memory_repositories.dart';
import 'package:seller_os/features/mock_data/domain/mock_dataset.dart';
import 'package:seller_os/features/mock_data/domain/services/demo_data_seeder.dart';

import '../../support/pump_app.dart';

/// **The seeder has to write every collection, and twice must equal once.**
///
/// It is what a demo account gets filled from, and it is also the only thing
/// that drives every live write path in one run — so a collection it silently
/// skips is a screen that is empty in front of an audience, and a row it
/// duplicates is a business whose totals stop adding up.
///
/// Run against the in-memory repositories rather than Firestore: the seeder
/// only knows the domain interfaces, so this pins its contract without a
/// backend. What it cannot prove is that Firestore accepts the documents —
/// that needs a real project.
void main() {
  late MockDataset seed;
  late MockStore store;
  late DemoDataSeeder seeder;

  setUp(() {
    seed = MockDataset.seed(now: testNow);
    // Emptied rather than constructed empty: `MockDataset`'s own constructor
    // is private, and a public "empty" factory would exist only for this test.
    store = MockStore(seed)
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

    seeder = DemoDataSeeder(
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
    expect(written, greaterThan(0));
  });

  test('seeding twice replaces rather than doubles', () async {
    final int first = await seeder.seed(seed);
    final int second = await seeder.seed(seed);

    expect(second, first);
    expect(store.items, hasLength(seed.items.length));
    expect(store.orders, hasLength(seed.orders.length));
  });

  test('keeps the dates the seed placed, so the demo looks lived-in', () async {
    await seeder.seed(seed);

    final Item seeded = seed.items.firstWhere(
      (Item item) => item.listedAt != null,
    );
    final Item stored = store.items.firstWhere(
      (Item item) => item.id == seeded.id,
    );

    // A row stamped "now" on the way in would empty Home's Needs Attention
    // block, which is the screen worth demoing.
    expect(stored.listedAt, seeded.listedAt);
    expect(stored.createdAt, seeded.createdAt);
  });
}

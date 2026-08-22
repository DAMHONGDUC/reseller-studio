import 'dart:async';

import '../../expenses/domain/entities/expense.dart';
import '../../expenses/domain/repositories/expense_repository.dart';
import '../../inventory/domain/entities/item.dart';
import '../../inventory/domain/entities/item_category.dart';
import '../../inventory/domain/entities/storage_location.dart';
import '../../inventory/domain/repositories/catalog_repository.dart';
import '../../inventory/domain/repositories/item_repository.dart';
import '../../listings/domain/entities/listing.dart';
import '../../listings/domain/repositories/listing_repository.dart';
import '../../offers/domain/entities/offer.dart';
import '../../offers/domain/repositories/offer_repository.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/domain/repositories/order_repository.dart';
import '../../sourcing/domain/entities/purchase.dart';
import '../../sourcing/domain/entities/source.dart';
import '../../sourcing/domain/repositories/sourcing_repository.dart';
import '../../subscription/domain/entities/plan_offering.dart';
import '../../subscription/domain/entities/subscription_status.dart';
import '../../subscription/domain/enums/seller_plan.dart';
import '../../subscription/domain/repositories/subscription_repository.dart';
import '../../workspace/domain/entities/user_profile.dart';
import '../../workspace/domain/entities/workspace.dart';
import '../../workspace/domain/repositories/workspace_repository.dart';
import '../domain/mock_dataset.dart';

/// The mutable world behind every in-memory repository.
///
/// One store, six repositories over it — rather than one class implementing
/// all six interfaces, which Dart cannot express: `ItemRepository.save(Item)`
/// and `OrderRepository.save(Order)` merge into a single member with
/// irreconcilable signatures.
///
/// **Nothing is persisted.** A restart re-seeds from [MockDataset.seed], and
/// that is deliberate: a mock that survived restarts would accumulate edits
/// and stop being the known-good dataset the screens are checked against.
class MockStore {
  MockStore(this.dataset)
    : items = List<Item>.of(dataset.items),
      orders = List<Order>.of(dataset.orders),
      listings = List<Listing>.of(dataset.listings),
      sources = List<Source>.of(dataset.sources),
      purchases = List<Purchase>.of(dataset.purchases),
      expenses = List<Expense>.of(dataset.expenses),
      categories = List<ItemCategory>.of(dataset.categories),
      locations = List<StorageLocation>.of(dataset.locations),
      offers = List<Offer>.of(dataset.offers),
      workspace = dataset.workspace;

  /// Seeded from the current clock, so the demo data is always recent.
  factory MockStore.seeded({DateTime? now}) =>
      MockStore(MockDataset.seed(now: now ?? DateTime.now()));

  final MockDataset dataset;

  final List<Item> items;
  final List<Order> orders;
  final List<Listing> listings;
  final List<Source> sources;
  final List<Purchase> purchases;
  final List<Expense> expenses;
  final List<ItemCategory> categories;
  final List<StorageLocation> locations;
  final List<Offer> offers;

  /// The demo business itself, mutable because Settings can now change it.
  ///
  /// Copied off the dataset rather than read through it: the dataset is the
  /// known-good seed every test asserts against, and an edit that reached back
  /// into it would change what the next screen was checked against.
  Workspace workspace;

  /// The demo business starts on the free tier, so the limits and the paywall
  /// are what a developer sees first. `InMemorySubscriptionRepository` moves
  /// it; nothing else does.
  SellerPlan plan = SellerPlan.free;

  // Broadcast because several screens watch the same collection at once —
  // Home counts orders while the Orders tab lists them. A single-subscription
  // stream throws on the second listener.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Emit the current value immediately, then again on every change.
  ///
  /// The immediate emission is what makes a screen render on its first frame
  /// instead of sitting on a spinner until something happens to change —
  /// Firestore's snapshot listeners behave the same way, so screens written
  /// against this behave identically against the real backend.
  Stream<T> watch<T>(T Function() read) async* {
    yield read();

    yield* _changes.stream.map((void _) => read());
  }

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() {
    unawaited(_changes.close());
  }

  /// Insert or replace by id, then publish.
  void upsert<T>(List<T> list, T value, bool Function(T) matches) {
    final int index = list.indexWhere(matches);

    if (index == -1) {
      list.add(value);
    } else {
      list[index] = value;
    }

    notifyChanged();
  }
}

class InMemoryItemRepository implements ItemRepository {
  const InMemoryItemRepository(this._store);

  final MockStore _store;

  List<Item> get _live {
    final List<Item> live =
        _store.items.where((Item item) => !item.isDeleted).toList()
          ..sort((Item a, Item b) => b.createdAt.compareTo(a.createdAt));

    return live;
  }

  @override
  Stream<List<Item>> watchItems() => _store.watch(() => _live);

  @override
  Stream<Item?> watchItem(String id) => _store.watch(
    () => _store.items.where((Item i) => i.id == id).firstOrNull,
  );

  @override
  Future<Item?> findById(String id) async =>
      _store.items.where((Item item) => item.id == id).firstOrNull;

  @override
  Stream<List<Item>> watchItemsForPurchase(String purchaseId) => _store.watch(
    () => _live.where((Item item) => item.purchaseId == purchaseId).toList(),
  );

  @override
  Future<void> save(Item item) async =>
      _store.upsert(_store.items, item, (Item other) => other.id == item.id);

  @override
  Future<void> saveAll(List<Item> items) async {
    for (final Item item in items) {
      final int index = _store.items.indexWhere((Item o) => o.id == item.id);

      if (index == -1) {
        _store.items.add(item);
      } else {
        _store.items[index] = item;
      }
    }

    // One notification for the whole batch, not one per row — hard rule 16's
    // bulk path must not make forty screens rebuild forty times.
    _store.notifyChanged();
  }

  @override
  Future<void> delete(String id) async {
    final int index = _store.items.indexWhere((Item item) => item.id == id);

    if (index == -1) return;

    // Soft delete (hard rule 15): the row stays joinable by the orders and
    // purchases that reference it.
    _store.items[index] = _store.items[index].copyWith(
      deletedAt: DateTime.now(),
    );
    _store.notifyChanged();
  }
}

class InMemoryOrderRepository implements OrderRepository {
  const InMemoryOrderRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Order>> watchOrders() => _store.watch(() {
    final List<Order> sorted = List<Order>.of(_store.orders)
      ..sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));

    return sorted;
  });

  @override
  Stream<Order?> watchOrder(String id) => _store.watch(
    () => _store.orders.where((Order order) => order.id == id).firstOrNull,
  );

  @override
  Future<Order?> findById(String id) async =>
      _store.orders.where((Order order) => order.id == id).firstOrNull;

  @override
  Future<void> save(Order order) async => _store.upsert(
    _store.orders,
    order,
    (Order other) => other.id == order.id,
  );
}

class InMemoryListingRepository implements ListingRepository {
  const InMemoryListingRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Listing>> watchListings() =>
      _store.watch(() => List<Listing>.of(_store.listings));

  @override
  Stream<List<Listing>> watchListingsForItem(String itemId) => _store.watch(
    () => _store.listings.where((Listing l) => l.itemId == itemId).toList(),
  );

  @override
  Future<void> save(Listing listing) async => _store.upsert(
    _store.listings,
    listing,
    (Listing other) => other.id == listing.id,
  );

  @override
  Future<void> saveAll(List<Listing> listings) async {
    for (final Listing listing in listings) {
      final int index = _store.listings.indexWhere(
        (Listing other) => other.id == listing.id,
      );

      if (index == -1) {
        _store.listings.add(listing);
      } else {
        _store.listings[index] = listing;
      }
    }

    _store.notifyChanged();
  }
}

class InMemorySourceRepository implements SourceRepository {
  const InMemorySourceRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Source>> watchSources() => _store.watch(
    () => _store.sources.where((Source source) => !source.isDeleted).toList(),
  );

  @override
  Future<Source?> findById(String id) async =>
      _store.sources.where((Source source) => source.id == id).firstOrNull;

  @override
  Future<void> save(Source source) async => _store.upsert(
    _store.sources,
    source,
    (Source other) => other.id == source.id,
  );

  @override
  Future<void> delete(String id) async {
    _store.sources.removeWhere((Source source) => source.id == id);
    _store.notifyChanged();
  }
}

class InMemoryPurchaseRepository implements PurchaseRepository {
  const InMemoryPurchaseRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Purchase>> watchPurchases() => _store.watch(() {
    final List<Purchase> live =
        _store.purchases
            .where((Purchase purchase) => !purchase.isDeleted)
            .toList()
          ..sort(
            (Purchase a, Purchase b) =>
                b.purchaseDate.compareTo(a.purchaseDate),
          );

    return live;
  });

  @override
  Stream<List<Purchase>> watchPurchasesForSource(String sourceId) =>
      _store.watch(
        () => _store.purchases
            .where((Purchase p) => p.sourceId == sourceId && !p.isDeleted)
            .toList(),
      );

  @override
  Future<Purchase?> findById(String id) async =>
      _store.purchases.where((Purchase p) => p.id == id).firstOrNull;

  @override
  Future<void> save(Purchase purchase) async => _store.upsert(
    _store.purchases,
    purchase,
    (Purchase other) => other.id == purchase.id,
  );

  @override
  Future<void> delete(String id) async {
    _store.purchases.removeWhere((Purchase purchase) => purchase.id == id);
    _store.notifyChanged();
  }
}

class InMemoryOfferRepository implements OfferRepository {
  const InMemoryOfferRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Offer>> watchOffers() => _store.watch(() {
    final List<Offer> sorted = List<Offer>.of(_store.offers)
      ..sort((Offer a, Offer b) => b.createdAt.compareTo(a.createdAt));

    return sorted;
  });

  @override
  Future<void> save(Offer offer) async => _store.upsert(
    _store.offers,
    offer,
    (Offer other) => other.id == offer.id,
  );
}

class InMemoryCategoryRepository implements CategoryRepository {
  const InMemoryCategoryRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<ItemCategory>> watchCategories() => _store.watch(() {
    final List<ItemCategory> live =
        _store.categories
            .where((ItemCategory category) => !category.isDeleted)
            .toList()
          ..sort((ItemCategory a, ItemCategory b) => a.name.compareTo(b.name));

    return live;
  });

  @override
  Future<void> save(ItemCategory category) => Future<void>.sync(
    () => _store.upsert(
      _store.categories,
      category,
      (ItemCategory other) => other.id == category.id,
    ),
  );

  @override
  Future<void> delete(String id) async {
    final int index = _store.categories.indexWhere(
      (ItemCategory category) => category.id == id,
    );

    if (index == -1) return;

    _store.categories[index] = _store.categories[index].copyWith(
      deletedAt: DateTime.now(),
    );
    _store.notifyChanged();
  }
}

class InMemoryLocationRepository implements LocationRepository {
  const InMemoryLocationRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<StorageLocation>> watchLocations() => _store.watch(
    () => _store.locations
        .where((StorageLocation location) => !location.isDeleted)
        .toList(),
  );

  @override
  Future<void> save(StorageLocation location) => Future<void>.sync(
    () => _store.upsert(
      _store.locations,
      location,
      (StorageLocation other) => other.id == location.id,
    ),
  );

  @override
  Future<void> delete(String id) async {
    final int index = _store.locations.indexWhere(
      (StorageLocation location) => location.id == id,
    );

    if (index == -1) return;

    _store.locations[index] = _store.locations[index].copyWith(
      deletedAt: DateTime.now(),
    );
    _store.notifyChanged();
  }
}

class InMemoryExpenseRepository implements ExpenseRepository {
  const InMemoryExpenseRepository(this._store);

  final MockStore _store;

  @override
  Stream<List<Expense>> watchExpenses() => _store.watch(() {
    final List<Expense> live =
        _store.expenses.where((Expense expense) => !expense.isDeleted).toList()
          ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

    return live;
  });

  @override
  Stream<List<Expense>> watchExpensesForOrder(String orderId) => _store.watch(
    () => _store.expenses.where((Expense e) => e.orderId == orderId).toList(),
  );

  @override
  Future<void> save(Expense expense) async => _store.upsert(
    _store.expenses,
    expense,
    (Expense other) => other.id == expense.id,
  );

  @override
  Future<void> delete(String id) async {
    _store.expenses.removeWhere((Expense expense) => expense.id == id);
    _store.notifyChanged();
  }
}

/// A billing backend with no store behind it.
///
/// **Purchases succeed here, and that is the point.** Every other in-memory
/// repository exists so a screen can be looked at before Firebase; this one
/// exists so the *paywall and the limits* can be walked end to end before
/// RevenueCat — hit the free item cap, upgrade, watch the cap lift. A mock
/// that refused to buy would leave the whole gating path unexercised until
/// the day the store is live.
///
/// Nothing is persisted, so a restart puts the demo business back on Free.
class InMemorySubscriptionRepository implements SubscriptionRepository {
  const InMemorySubscriptionRepository(this._store);

  /// What the fake store sells. Prices are formatted strings for the same
  /// reason the real ones are — see `PlanOffering`.
  static const List<PlanOffering> catalogue = <PlanOffering>[
    PlanOffering(
      productId: 'mock_pro_monthly',
      plan: SellerPlan.pro,
      period: BillingPeriod.monthly,
      formattedPrice: r'$9.99',
    ),
    PlanOffering(
      productId: 'mock_pro_yearly',
      plan: SellerPlan.pro,
      period: BillingPeriod.yearly,
      formattedPrice: r'$89.99',
    ),
    PlanOffering(
      productId: 'mock_business_monthly',
      plan: SellerPlan.business,
      period: BillingPeriod.monthly,
      formattedPrice: r'$24.99',
    ),
    PlanOffering(
      productId: 'mock_business_yearly',
      plan: SellerPlan.business,
      period: BillingPeriod.yearly,
      formattedPrice: r'$229.99',
    ),
  ];

  final MockStore _store;

  @override
  Stream<SubscriptionStatus> watchStatus() => _store.watch(_read);

  @override
  Future<List<PlanOffering>> offerings() async => catalogue;

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async {
    _store.plan = offering.plan;
    _store.notifyChanged();

    return _read();
  }

  /// Nothing to restore from — the fake store has no history, and returning
  /// the current plan is the honest answer rather than a reset to Free.
  @override
  Future<SubscriptionStatus> restore() async => _read();

  SubscriptionStatus _read() => _store.plan.isPaid
      ? SubscriptionStatus(
          plan: _store.plan,
          source: SubscriptionSource.appStore,
          renewsAt: DateTime.now().add(MockPlanConstant.mockRenewal),
          willRenew: true,
        )
      : SubscriptionStatus.free;
}

/// The one number the fake subscription needs.
final class MockPlanConstant {
  /// How far out a mock purchase renews. A month, so the Subscription screen
  /// has a plausible date to render rather than an empty row.
  static const Duration mockRenewal = Duration(days: 30);
}

/// The demo business, editable the way the real one is.
///
/// **The account half is deliberately inert.** Mock mode has no account by
/// construction (`lib/features/mock_data/CLAUDE.md`), so a profile, a second
/// workspace and a "reopen this one next time" pointer have nothing to mean.
/// They are no-ops rather than throws: a demo that crashed on sign-in
/// bookkeeping would be a worse backend than none.
class InMemoryWorkspaceRepository implements WorkspaceRepository {
  const InMemoryWorkspaceRepository(this._store);

  final MockStore _store;

  @override
  Stream<Workspace?> watchWorkspace(String workspaceId) =>
      _store.watch(() => _store.workspace);

  @override
  Stream<List<Member>> watchMembers(String workspaceId) =>
      _store.watch(() => _store.dataset.members);

  @override
  Future<void> updateWorkspace(Workspace workspace) async {
    _store.workspace = workspace;
    _store.notifyChanged();
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      Stream<UserProfile?>.value(null);

  @override
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {}

  /// Returns the demo business rather than making a second one: the mock
  /// world holds exactly one, and handing back a new id would point every
  /// repository at a workspace with nothing in it.
  @override
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
  }) async => _store.workspace.id;

  @override
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  }) async {}
}

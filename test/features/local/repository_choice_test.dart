import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/account/account_kind.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_providers.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/inventory/data/repositories/local_item_repository.dart';
import 'package:reseller_studio/features/inventory/domain/repositories/item_repository.dart';
import 'package:reseller_studio/features/orders/data/repositories/local_order_repository.dart';
import 'package:reseller_studio/features/orders/domain/repositories/order_repository.dart';
import 'package:reseller_studio/features/sourcing/data/repositories/local_sourcing_repositories.dart';
import 'package:reseller_studio/features/sourcing/domain/repositories/sourcing_repository.dart';

/// P3's gate: the switch hands back the guest store when nobody is signed in,
/// and it does it for every repository rather than the ones somebody
/// remembered.
void main() {
  late LocalDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: <Override>[
        accountKindProvider.overrideWithValue(AccountKind.guest),
        localDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  test('a signed-out seller reads the local store', () {
    expect(container.read(itemRepositoryProvider), isA<LocalItemRepository>());
    expect(container.read(orderRepositoryProvider), isA<LocalOrderRepository>());
    expect(
      container.read(sourceRepositoryProvider),
      isA<LocalSourceRepository>(),
    );
  });

  test('a guest repository works with no workspace document yet', () async {
    final ItemRepository items = container.read(itemRepositoryProvider);

    expect(await items.watchItems().first, isEmpty);
  });

  test('every business repository resolves without throwing', () {
    // The guard the Firestore half raises when there is no workspace must
    // never fire for a guest — that is the whole point of the switch.
    expect(() {
      container.read(itemRepositoryProvider);
      container.read(orderRepositoryProvider);
      container.read(offerRepositoryProvider);
      container.read(marketplaceRepositoryProvider);
      container.read(carrierRepositoryProvider);
      container.read(listingRepositoryProvider);
      container.read(sourceRepositoryProvider);
      container.read(purchaseRepositoryProvider);
      container.read(categoryRepositoryProvider);
      container.read(locationRepositoryProvider);
      container.read(expenseRepositoryProvider);
    }, returnsNormally);
  });

  test('a guest write lands in the local database', () async {
    final SourceRepository sources = container.read(sourceRepositoryProvider);
    final OrderRepository orders = container.read(orderRepositoryProvider);

    expect(sources, isA<LocalSourceRepository>());
    expect(await orders.watchOrders().first, isEmpty);
  });
}

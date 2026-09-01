import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart'
    as record;
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';

import '../../support/pump_app.dart';

/// **One order, wherever marketplaces are drawn** — the enum's declaration
/// order for the platforms a listing names, and the order the business was
/// given them in for the records it owns. Both used to come out of a query
/// unordered, so the same two marketplaces read one way on an item's detail
/// screen and the other way on the screen that prices them.
void main() {
  Listing listing(String id, Marketplace marketplace) => Listing(
    id: id,
    itemId: 'itm-order',
    marketplace: marketplace,
    title: 'Wool coat',
    price: const Money(4500, 'USD'),
    status: ListingStatus.active,
    createdAt: testNow,
  );

  test('an item’s listings arrive in the marketplaces’ own order', () async {
    final ProviderContainer container = mockContainer();

    // Written back to front, which is exactly what a document order may hand
    // back and what nothing downstream may depend on.
    await container.read(listingRepositoryProvider).saveAll(<Listing>[
      listing('l-3', Marketplace.poshmark),
      listing('l-2', Marketplace.depop),
      listing('l-1', Marketplace.ebay),
    ]);

    container.listen<AsyncValue<List<Listing>>>(
      listingsForItemProvider('itm-order'),
      (AsyncValue<List<Listing>>? previous, AsyncValue<List<Listing>> next) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    expect(
      container
          .read(listingsForItemProvider('itm-order'))
          .value!
          .map((Listing row) => row.marketplace)
          .toList(),
      <Marketplace>[Marketplace.ebay, Marketplace.depop, Marketplace.poshmark],
    );
  });

  test('the seeded marketplaces are a millisecond apart, not one instant', () {
    // Five identical stamps leave `orderBy('createdAt')` to break the tie by
    // document id: the seeded order in mock data, alphabetical in Firestore.
    final ProviderContainer container = mockContainer();
    final List<record.Marketplace> defaults = container.read(
      defaultMarketplacesProvider,
    );
    final List<DateTime> stamps = defaults
        .map((record.Marketplace marketplace) => marketplace.createdAt)
        .toList();

    expect(defaults.map((record.Marketplace m) => m.id).toList(), <String>[
      'ebay',
      'etsy',
      'depop',
      'poshmark',
      'vinted',
    ]);
    expect(stamps.toSet(), hasLength(stamps.length));
    expect(
      List<DateTime>.of(stamps)
        ..sort((DateTime a, DateTime b) => a.compareTo(b)),
      stamps,
    );
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/local/drain/drain_table.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/listings/data/repositories/local_listing_repository.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing_price_change.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/domain/enums/price_change_reason.dart';
import 'package:reseller_studio/features/listings/domain/services/listing_price_changes.dart';

/// A listing's price history: worked out in one place, written in the same
/// write as the price, and carried to the account when a guest signs in.
void main() {
  Listing listing(String id, int minor) => Listing(
    id: id,
    itemId: 'itm-1',
    marketplaceId: 'ebay',
    marketplaceName: 'eBay',
    title: 'Trucker jacket',
    price: Money(minor, 'USD'),
    status: ListingStatus.active,
    createdAt: DateTime(2026, 10, 1),
  );

  group('ListingPriceChanges.between', () {
    test('records a moved price with its reason', () {
      final List<ListingPriceChange> changes = ListingPriceChanges.between(
        before: <Listing>[listing('l1', 4500), listing('l2', 4200)],
        after: <Listing>[listing('l1', 3999), listing('l2', 4200)],
        reason: PriceChangeReason.bulk,
        at: DateTime(2026, 10, 11),
      );

      expect(changes, hasLength(1));
      expect(changes.single.listingId, 'l1');
      expect(changes.single.from, const Money(4500, 'USD'));
      expect(changes.single.to, const Money(3999, 'USD'));
      expect(changes.single.reason, PriceChangeReason.bulk);
    });

    test('a new listing is not a reprice', () {
      expect(
        ListingPriceChanges.between(
          before: const <Listing>[],
          after: <Listing>[listing('l1', 4500)],
          reason: PriceChangeReason.manual,
          at: DateTime(2026, 10, 11),
        ),
        isEmpty,
      );
    });
  });

  group('the guest store', () {
    late LocalDatabase db;

    setUp(() => db = LocalDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('saves a price and its history together', () async {
      final LocalListingRepository repository = LocalListingRepository(
        db,
        currency: 'USD',
      );
      final List<ListingPriceChange> changes = ListingPriceChanges.between(
        before: <Listing>[listing('l1', 4500)],
        after: <Listing>[listing('l1', 3999)],
        reason: PriceChangeReason.manual,
        at: DateTime(2026, 10, 11),
      );

      await repository.saveAll(<Listing>[
        listing('l1', 3999),
      ], priceChanges: changes);

      final List<ListingPriceChange> history = await repository
          .watchPriceChangesForItem('itm-1')
          .first;

      expect(history, hasLength(1));
      expect(history.single.to, const Money(3999, 'USD'));
    });

    test('every guest table is drained, the new ones included', () {
      final Set<String> drained = <String>{
        for (final DrainTable table in DrainTable.all(db)) table.name,
      };

      expect(
        drained,
        containsAll(<String>['pricing_rules', 'listing_price_changes']),
      );
      expect(drained, hasLength(db.drainOrder.length));
    });
  });
}

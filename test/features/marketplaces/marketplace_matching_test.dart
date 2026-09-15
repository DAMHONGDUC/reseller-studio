import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/domain/services/marketplace_matching.dart';
import 'package:reseller_studio/features/marketplaces/domain/services/marketplace_rate_input_utils.dart';

/// Joining a listing's platform back to the marketplace record the business
/// owns.
///
/// **Two types are called `Marketplace`**: the closed enum a listing carries,
/// and the record a seller owns and renames. Nothing stores a foreign key
/// between them, so the join is by key — id first, name second — and a join
/// written at a call site is one every other call site would write
/// differently.
void main() {
  Marketplace record(String id, String name) =>
      Marketplace(id: id, name: name, createdAt: DateTime(2026, 1, 1));

  group('valueFor', () {
    test('matches on the id first', () {
      // A seeded record's id is the enum's own name, which is exact.
      expect(
        MarketplaceMatching.valueFor(
          record('ebay', 'My eBay shop'),
          <String, int>{'ebay': 7},
        ),
        7,
      );
    });

    test('falls back to the name for a record the seller made', () {
      expect(
        MarketplaceMatching.valueFor(record('uuid-1', 'Depop'), <String, int>{
          'depop': 3,
        }),
        3,
      );
    });

    test('ignores case on both sides', () {
      expect(
        MarketplaceMatching.valueFor(record('uuid-1', 'DEPOP'), <String, int>{
          'Depop': 3,
        }),
        3,
      );
    });

    test('a platform not in the map is null, not a missing price', () {
      expect(
        MarketplaceMatching.valueFor(record('vinted', 'Vinted'), <String, int>{
          'ebay': 7,
        }),
        isNull,
      );
    });
  });

  group('matching', () {
    final List<Marketplace> owned = <Marketplace>[
      record('ebay', 'eBay'),
      record('depop', 'Depop'),
      record('uuid-1', 'Church hall stall'),
    ];

    test('returns the records named, in the list own order', () {
      expect(
        MarketplaceMatching.matching(owned, <String>{
          'Church hall stall',
          'ebay',
        }).map((Marketplace row) => row.id).toList(),
        <String>['ebay', 'uuid-1'],
      );
    });

    test('names nothing the business still has is an empty answer', () {
      expect(MarketplaceMatching.matching(owned, <String>{'vinted'}), isEmpty);
    });
  });

  group('the fee rate typed into the form', () {
    test('a percentage becomes a rate', () {
      expect(MarketplaceRateInputUtils.parse('12.9'), closeTo(0.129, 1e-9));
    });

    test('a comma is a decimal separator too', () {
      // Device keyboards follow the locale, and the seller typed what theirs
      // gave them.
      expect(MarketplaceRateInputUtils.parse('12,9'), closeTo(0.129, 1e-9));
    });

    test('anything unreadable is null rather than zero', () {
      expect(MarketplaceRateInputUtils.parse('about ten percent'), isNull);
      expect(MarketplaceRateInputUtils.parse('  '), isNull);
    });
  });
}

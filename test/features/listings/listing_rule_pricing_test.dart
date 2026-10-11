import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/domain/services/listing_rule_pricing.dart';
import 'package:reseller_studio/features/pricing/domain/entities/pricing_rule.dart';
import 'package:reseller_studio/features/pricing/domain/enums/pricing_rule_scope.dart';

/// A rule applied to a selection prices what it can prove and leaves the
/// rest alone.
void main() {
  Listing listing(String id, String marketplaceId, int minor) => Listing(
    id: id,
    itemId: 'itm-$id',
    marketplaceId: marketplaceId,
    marketplaceName: marketplaceId,
    title: 'Jacket',
    price: Money(minor, 'USD'),
    status: ListingStatus.active,
    createdAt: DateTime(2026, 10, 1),
  );
  final PricingRule double = PricingRule(
    id: 'rule-1',
    name: 'Double',
    createdAt: DateTime(2026, 10, 1),
    multiplier: 2,
  );
  final Map<String, Money?> costs = <String, Money?>{
    'itm-a': const Money(1000, 'USD'),
    'itm-b': null,
    'itm-c': const Money(1500, 'USD'),
  };

  test('reprices the listings with a cost and skips the rest', () {
    final RuleRepricing result = ListingRulePricing.apply(
      listings: <Listing>[
        listing('a', 'ebay', 4500),
        listing('b', 'ebay', 4500),
        listing('c', 'ebay', 3000),
      ],
      rule: double,
      feeRate: 0,
      costOf: (Listing l) => costs[l.itemId],
      categoryOf: (Listing l) => null,
    );

    expect(result.repriced.map((Listing l) => l.price), <Money>[
      const Money(2000, 'USD'),
    ]);
    expect(result.skipped, 1);
  });

  test('a marketplace rule leaves other marketplaces alone', () {
    final RuleRepricing result = ListingRulePricing.apply(
      listings: <Listing>[listing('a', 'ebay', 4500), listing('c', 'etsy', 0)],
      rule: double.copyWith(
        scope: PricingRuleScope.marketplace,
        scopeId: 'etsy',
      ),
      feeRate: 0,
      costOf: (Listing l) => costs[l.itemId],
      categoryOf: (Listing l) => null,
    );

    expect(result.repriced.single.id, 'c');
    expect(result.skipped, 1);
  });
}

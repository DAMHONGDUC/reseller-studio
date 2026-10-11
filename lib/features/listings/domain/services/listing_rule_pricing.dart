import '../../../../core/money/money.dart';
import '../../../pricing/domain/entities/pricing_quote.dart';
import '../../../pricing/domain/entities/pricing_rule.dart';
import '../../../pricing/domain/enums/pricing_rule_scope.dart';
import '../../../pricing/domain/services/pricing_rule_calculator.dart';
import '../entities/listing.dart';

/// What applying a rule to a selection did.
class RuleRepricing {
  const RuleRepricing({required this.repriced, required this.skipped});

  /// The listings whose price the rule moved, at their new price.
  final List<Listing> repriced;

  /// Listings left alone: no cost recorded, or outside the rule's scope. A
  /// rule never guesses a cost (hard rule 5), so these keep their price.
  final int skipped;
}

/// A pricing rule applied to a selection of listings (hard rule 16).
final class ListingRulePricing {
  static RuleRepricing apply({
    required List<Listing> listings,
    required PricingRule rule,
    required double feeRate,
    required Money? Function(Listing listing) costOf,
    required String? Function(Listing listing) categoryOf,
  }) {
    final List<Listing> repriced = <Listing>[];
    int skipped = 0;

    for (final Listing listing in listings) {
      final PricingQuote? quote = _inScope(rule, listing, categoryOf)
          ? PricingRuleCalculator.quote(
              cost: costOf(listing),
              rule: rule,
              feeRate: feeRate,
            )
          : null;

      if (quote == null || quote.price.currency != listing.price.currency) {
        skipped++;
        continue;
      }
      if (quote.price != listing.price) {
        repriced.add(listing.copyWith(price: quote.price));
      }
    }

    return RuleRepricing(repriced: repriced, skipped: skipped);
  }

  static bool _inScope(
    PricingRule rule,
    Listing listing,
    String? Function(Listing listing) categoryOf,
  ) => switch (rule.scope) {
    PricingRuleScope.all => true,
    PricingRuleScope.marketplace => listing.marketplaceId == rule.scopeId,
    PricingRuleScope.category => categoryOf(listing) == rule.scopeId,
  };
}

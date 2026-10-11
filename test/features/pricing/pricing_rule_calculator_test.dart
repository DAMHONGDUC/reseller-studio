import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/pricing/domain/entities/pricing_quote.dart';
import 'package:reseller_studio/features/pricing/domain/entities/pricing_rule.dart';
import 'package:reseller_studio/features/pricing/domain/enums/price_rounding.dart';
import 'package:reseller_studio/features/pricing/domain/services/pricing_rule_calculator.dart';

/// A pricing rule turns a cost into an asking price, and refuses whenever the
/// answer could not be defended (hard rules 4 and 5).
void main() {
  PricingRule rule({
    double multiplier = 2,
    Money? fixedAdd,
    PriceRounding rounding = PriceRounding.none,
    Money? minProfit,
    int? minSupplierStock,
    int? staleDays,
    double? staleDropPercent,
  }) => PricingRule(
    id: 'rule-1',
    name: 'Double it',
    createdAt: DateTime(2026, 10, 1),
    multiplier: multiplier,
    fixedAdd: fixedAdd,
    rounding: rounding,
    minProfit: minProfit,
    minSupplierStock: minSupplierStock,
    staleDays: staleDays,
    staleDropPercent: staleDropPercent,
  );

  group('quote', () {
    test('multiplies, adds and reports the profit after the planning fee', () {
      final PricingQuote? quote = PricingRuleCalculator.quote(
        cost: const Money(1000, 'USD'),
        rule: rule(fixedAdd: const Money(500, 'USD')),
        feeRate: 0.1,
      );

      expect(quote?.price, const Money(2500, 'USD'));
      expect(quote?.floor, const Money(1112, 'USD'));
      expect(quote?.expectedProfit, const Money(1250, 'USD'));
    });

    test('never prices under the floor the minimum profit sets', () {
      final PricingQuote? quote = PricingRuleCalculator.quote(
        cost: const Money(1000, 'USD'),
        rule: rule(multiplier: 1, minProfit: const Money(800, 'USD')),
        feeRate: 0.1,
      );

      expect(quote?.price, const Money(2000, 'USD'));
      expect(quote!.expectedProfit >= const Money(800, 'USD'), isTrue);
    });

    test('rounds up to .99 and to a whole unit, never down', () {
      final PricingQuote? ninetyNine = PricingRuleCalculator.quote(
        cost: const Money(1170, 'USD'),
        rule: rule(rounding: PriceRounding.ninetyNine),
        feeRate: 0,
      );
      final PricingQuote? whole = PricingRuleCalculator.quote(
        cost: const Money(1170, 'USD'),
        rule: rule(rounding: PriceRounding.whole),
        feeRate: 0,
      );

      expect(ninetyNine?.price, const Money(2399, 'USD'));
      expect(whole?.price, const Money(2400, 'USD'));
    });

    test('is null when no cost is recorded', () {
      expect(
        PricingRuleCalculator.quote(cost: null, rule: rule(), feeRate: 0.1),
        isNull,
      );
    });

    test('is null when the rule is written in another currency', () {
      expect(
        PricingRuleCalculator.quote(
          cost: const Money(1000, 'GBP'),
          rule: rule(fixedAdd: const Money(500, 'USD')),
          feeRate: 0.1,
        ),
        isNull,
      );
    });

    test('is null when the fee rate would take everything', () {
      expect(
        PricingRuleCalculator.quote(
          cost: const Money(1000, 'USD'),
          rule: rule(),
          feeRate: 1,
        ),
        isNull,
      );
    });

    test('leaves a zero-decimal currency unrounded', () {
      final PricingQuote? quote = PricingRuleCalculator.quote(
        cost: const Money(1170, 'JPY'),
        rule: rule(rounding: PriceRounding.ninetyNine),
        feeRate: 0,
      );

      expect(quote?.price, const Money(2340, 'JPY'));
    });
  });

  group('staleDrop', () {
    test('lowers by the step, rounded down', () {
      expect(
        PricingRuleCalculator.staleDrop(
          current: const Money(2999, 'USD'),
          cost: const Money(1000, 'USD'),
          rule: rule(
            rounding: PriceRounding.ninetyNine,
            staleDays: 30,
            staleDropPercent: 0.1,
          ),
          feeRate: 0.1,
        ),
        const Money(2699, 'USD'),
      );
    });

    test('stops at the floor rather than going under it', () {
      expect(
        PricingRuleCalculator.staleDrop(
          current: const Money(1300, 'USD'),
          cost: const Money(1000, 'USD'),
          rule: rule(
            minProfit: const Money(100, 'USD'),
            staleDays: 30,
            staleDropPercent: 0.5,
          ),
          feeRate: 0.1,
        ),
        const Money(1223, 'USD'),
      );
    });

    test('is null when the price is already at the floor', () {
      expect(
        PricingRuleCalculator.staleDrop(
          current: const Money(1112, 'USD'),
          cost: const Money(1000, 'USD'),
          rule: rule(staleDays: 30, staleDropPercent: 0.1),
          feeRate: 0.1,
        ),
        isNull,
      );
    });

    test('is null with no cost, since the floor cannot be known', () {
      expect(
        PricingRuleCalculator.staleDrop(
          current: const Money(2999, 'USD'),
          cost: null,
          rule: rule(staleDays: 30, staleDropPercent: 0.1),
          feeRate: 0.1,
        ),
        isNull,
      );
    });

    test('is null when the rule does not drop', () {
      expect(
        PricingRuleCalculator.staleDrop(
          current: const Money(2999, 'USD'),
          cost: const Money(1000, 'USD'),
          rule: rule(),
          feeRate: 0.1,
        ),
        isNull,
      );
    });
  });

  group('belowMinimumStock', () {
    test('uses the rule threshold, and zero without one', () {
      expect(
        PricingRuleCalculator.belowMinimumStock(
          stock: 3,
          rule: rule(minSupplierStock: 5),
        ),
        isTrue,
      );
      expect(PricingRuleCalculator.belowMinimumStock(stock: 0), isTrue);
      expect(PricingRuleCalculator.belowMinimumStock(stock: 1), isFalse);
    });

    test('unknown stock is not out of stock', () {
      expect(PricingRuleCalculator.belowMinimumStock(stock: null), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/money/money.dart';
import 'package:seller_os/features/pricing/domain/services/profit_calculator.dart';

/// Testing priority 1. These are the numbers a seller makes buying decisions
/// with, and hard rule 3 means they are recomputed on every read rather than
/// stored — so a bug here is wrong everywhere at once, silently.
void main() {
  const String usd = 'USD';

  Money usdOf(int minor) => Money(minor, usd);

  group('ProfitBreakdown', () {
    test('subtracts every cost from revenue', () {
      final ProfitBreakdown breakdown = ProfitBreakdown(
        revenue: usdOf(6000),
        cogs: usdOf(2000),
        fees: usdOf(800),
        shipping: usdOf(700),
        otherExpenses: usdOf(0),
      );

      expect(breakdown.totalCost, usdOf(3500));
      expect(breakdown.netProfit, usdOf(2500));
    });

    test('margin divides by revenue, ROI divides by cost', () {
      final ProfitBreakdown breakdown = ProfitBreakdown(
        revenue: usdOf(6000),
        cogs: usdOf(2000),
        fees: usdOf(800),
        shipping: usdOf(700),
        otherExpenses: usdOf(0),
      );

      // $25 profit on $60 taken.
      expect(breakdown.margin, closeTo(2500 / 6000, 1e-9));
      // $25 profit on $35 spent — a different question, and a bigger number.
      expect(breakdown.roi, closeTo(2500 / 3500, 1e-9));
    });

    test('an unknown cost makes profit unknown, NOT the whole sale price', () {
      final ProfitBreakdown breakdown = ProfitBreakdown(
        revenue: usdOf(6000),
        cogs: null,
        fees: usdOf(800),
        shipping: usdOf(700),
        otherExpenses: usdOf(0),
      );

      // Hard rule 5. Reporting $60 revenue as $45 profit because nobody typed
      // a cost would be the most misleading thing this app could say.
      expect(breakdown.netProfit, isNull);
      expect(breakdown.totalCost, isNull);
      expect(breakdown.margin, isNull);
      expect(breakdown.roi, isNull);
      expect(breakdown.isComplete, isFalse);
    });

    test('a free item has no ROI rather than an infinite one', () {
      final ProfitBreakdown breakdown = ProfitBreakdown(
        revenue: usdOf(6000),
        cogs: Money.zero(usd),
        fees: Money.zero(usd),
        shipping: Money.zero(usd),
        otherExpenses: Money.zero(usd),
      );

      expect(breakdown.netProfit, usdOf(6000));
      // Dividing by a zero cost is true and useless — `—` is the honest render.
      expect(breakdown.roi, isNull);
      expect(breakdown.margin, closeTo(1, 1e-9));
    });

    test('a sale under cost reports a negative profit, not a clamped zero', () {
      final ProfitBreakdown breakdown = ProfitBreakdown(
        revenue: usdOf(1000),
        cogs: usdOf(2000),
        fees: usdOf(150),
        shipping: usdOf(500),
        otherExpenses: Money.zero(usd),
      );

      expect(breakdown.netProfit, usdOf(-1650));
      expect(breakdown.netProfit!.isNegative, isTrue);
    });
  });

  group('PurchaseEvaluation — the plan §11 worked example', () {
    // The plan states these exact numbers:
    //   Buy price: $20 · Expected sale: $60 · Expected profit: $25
    //   Expected ROI: 125% · Maximum buy price: $30
    // With $15 of selling costs, which is what makes the stated profit $25.
    final PurchaseEvaluation evaluation = PurchaseEvaluation(
      buyPrice: usdOf(2000),
      expectedSalePrice: usdOf(6000),
      expectedFees: usdOf(800),
      expectedShipping: usdOf(700),
    );

    test('expected profit is \$25', () {
      expect(evaluation.expectedProfit, usdOf(2500));
    });

    test('expected ROI is 125%', () {
      expect(evaluation.expectedRoi, closeTo(1.25, 1e-9));
    });

    test('maximum buy price is \$30', () {
      // Derived from the 50% target ROI, not from a rule of thumb about the
      // sale price: net $45 / 1.5 = $30. If this fails, the derivation in
      // maximumBuyPrice's doc comment no longer matches the plan.
      expect(evaluation.maximumBuyPrice, usdOf(3000));
    });

    test('a \$20 buy clears the target, a \$35 buy does not', () {
      expect(evaluation.meetsTarget, isTrue);

      final PurchaseEvaluation tooExpensive = PurchaseEvaluation(
        buyPrice: usdOf(3500),
        expectedSalePrice: usdOf(6000),
        expectedFees: usdOf(800),
        expectedShipping: usdOf(700),
      );

      expect(tooExpensive.meetsTarget, isFalse);
      expect(tooExpensive.expectedProfit.isPositive, isTrue);
    });

    test('maximum buy price goes negative when costs exceed the sale', () {
      final PurchaseEvaluation underwater = PurchaseEvaluation(
        buyPrice: Money.zero(usd),
        expectedSalePrice: usdOf(1000),
        expectedFees: usdOf(800),
        expectedShipping: usdOf(900),
      );

      // Not worth taking for free. Callers must not clamp this to zero — a
      // sourcing screen has to be able to say so out loud.
      expect(underwater.maximumBuyPrice.isNegative, isTrue);
      expect(underwater.meetsTarget, isFalse);
    });

    test('a higher target ROI lowers the maximum buy price', () {
      final PurchaseEvaluation strict = PurchaseEvaluation(
        buyPrice: usdOf(2000),
        expectedSalePrice: usdOf(6000),
        expectedFees: usdOf(800),
        expectedShipping: usdOf(700),
        targetRoi: 2,
      );

      // net $45 / 3 = $15.
      expect(strict.maximumBuyPrice, usdOf(1500));
      expect(strict.meetsTarget, isFalse);
    });
  });

  group('StaleInventoryPolicy', () {
    final DateTime now = DateTime(2026, 8, 12);

    test('a listing older than the threshold is stale', () {
      expect(
        StaleInventoryPolicy.isStale(
          DateTime(2026, 5, 1),
          now: now,
        ),
        isTrue,
      );
    });

    test('a recent listing is not', () {
      expect(
        StaleInventoryPolicy.isStale(DateTime(2026, 8, 1), now: now),
        isFalse,
      );
    });

    test('an item that was never listed is not stale', () {
      // It belongs in "Items to list", which is a different problem. Lumping
      // the two together hides both.
      expect(StaleInventoryPolicy.isStale(null, now: now), isFalse);
      expect(StaleInventoryPolicy.age(null, now: now), isNull);
    });

    test('the threshold is configurable per workspace', () {
      final DateTime listedAt = DateTime(2026, 7, 1);

      expect(
        StaleInventoryPolicy.isStale(listedAt, now: now),
        isFalse,
        reason: '42 days is inside the 60-day default',
      );
      expect(
        StaleInventoryPolicy.isStale(
          listedAt,
          now: now,
          threshold: const Duration(days: 30),
        ),
        isTrue,
      );
    });
  });
}

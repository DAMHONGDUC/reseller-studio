import '../../../../core/money/currency_decimals.dart';
import '../../../../core/money/money.dart';
import '../entities/pricing_quote.dart';
import '../entities/pricing_rule.dart';
import '../enums/price_rounding.dart';

/// Turns a cost into an asking price under a [PricingRule].
///
/// Every answer is null when it cannot be proven right: no cost recorded, a
/// rule written in another currency (hard rule 4), or a fee rate that leaves
/// nothing. A price nobody can defend is worse than none (hard rule 5).
final class PricingRuleCalculator {
  /// The price [rule] gives [cost], never under the rule's floor.
  static PricingQuote? quote({
    required Money? cost,
    required PricingRule rule,
    required double feeRate,
  }) {
    if (cost == null || !_appliesTo(rule, cost.currency, feeRate)) return null;

    final Money floor = floorFor(cost: cost, rule: rule, feeRate: feeRate);
    final Money marked =
        cost.applyRate(rule.multiplier) +
        (rule.fixedAdd ?? Money.zero(cost.currency));
    final Money price = roundUp(marked < floor ? floor : marked, rule.rounding);

    return PricingQuote(
      price: price,
      floor: floor,
      expectedProfit: profitAt(price: price, cost: cost, feeRate: feeRate),
    );
  }

  /// The lowest price that clears [rule]'s minimum profit after [feeRate].
  static Money floorFor({
    required Money cost,
    required PricingRule rule,
    required double feeRate,
  }) {
    final Money target = cost + (rule.minProfit ?? Money.zero(cost.currency));

    return Money((target.minor / (1 - feeRate)).ceil(), cost.currency);
  }

  /// What [price] leaves after the planning fee and [cost].
  static Money profitAt({
    required Money price,
    required Money cost,
    required double feeRate,
  }) => price - price.applyRate(feeRate) - cost;

  /// [amount] rounded up to [rounding] — never below what it was.
  static Money roundUp(Money amount, PriceRounding rounding) {
    final int unit = CurrencyDecimals.factorFor(amount.currency);
    final int minor = amount.minor;

    if (unit == 1 || minor <= 0) return amount;

    return switch (rounding) {
      PriceRounding.none => amount,
      PriceRounding.whole => Money(
        ((minor + unit - 1) ~/ unit) * unit,
        amount.currency,
      ),
      PriceRounding.ninetyNine => Money(
        ((minor + unit) ~/ unit) * unit - 1,
        amount.currency,
      ),
    };
  }

  static bool _appliesTo(PricingRule rule, String currency, double feeRate) {
    final Money? fixedAdd = rule.fixedAdd;
    final Money? minProfit = rule.minProfit;

    return feeRate >= 0 &&
        feeRate < 1 &&
        rule.multiplier > 0 &&
        (fixedAdd == null || fixedAdd.currency == currency) &&
        (minProfit == null || minProfit.currency == currency);
  }
}

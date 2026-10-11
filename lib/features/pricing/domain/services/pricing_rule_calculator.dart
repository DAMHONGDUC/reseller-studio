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

  /// The lower price a stale listing moves to, or null when it should not
  /// move — the rule does not drop, the floor cannot be known, or the step
  /// would not go below [current].
  static Money? staleDrop({
    required Money current,
    required Money? cost,
    required PricingRule rule,
    required double feeRate,
  }) {
    final double? percent = rule.staleDropPercent;

    if (!rule.dropsWhenStale || percent == null || cost == null) return null;
    if (current.currency != cost.currency) return null;
    if (!_appliesTo(rule, cost.currency, feeRate)) return null;

    final Money floor = roundUp(
      floorFor(cost: cost, rule: rule, feeRate: feeRate),
      rule.rounding,
    );
    final Money dropped = roundDown(
      current.applyRate(1 - percent),
      rule.rounding,
    );
    final Money next = dropped < floor ? floor : dropped;

    return next < current ? next : null;
  }

  /// Whether supplier [stock] is under what [rule] will sell from.
  ///
  /// Unknown stock is not "out": a supplier that reports no count has not
  /// said it has none.
  static bool belowMinimumStock({required int? stock, PricingRule? rule}) {
    final int minimum = rule?.minSupplierStock ?? 1;

    return stock != null && stock < minimum;
  }

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

  /// [amount] rounded down to [rounding] — never above what it was.
  static Money roundDown(Money amount, PriceRounding rounding) {
    final int unit = CurrencyDecimals.factorFor(amount.currency);
    final int minor = amount.minor;

    if (unit == 1 || minor <= 0) return amount;

    final int rounded = switch (rounding) {
      PriceRounding.none => minor,
      PriceRounding.whole => (minor ~/ unit) * unit,
      PriceRounding.ninetyNine => ((minor + 1) ~/ unit) * unit - 1,
    };

    return rounded > 0 ? Money(rounded, amount.currency) : amount;
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

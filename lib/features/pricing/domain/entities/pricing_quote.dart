import '../../../../core/money/money.dart';

/// What a pricing rule asks for one cost, and what it leaves the seller.
class PricingQuote {
  const PricingQuote({
    required this.price,
    required this.floor,
    required this.expectedProfit,
  });

  /// The asking price, rounded the rule's way.
  final Money price;

  /// The lowest price that still clears the rule's minimum profit after the
  /// planning fee.
  final Money floor;

  /// [price] less the planning fee and the cost — an estimate made before a
  /// sale exists, which is the one place hard rule 3 lets a rate in.
  final Money expectedProfit;
}

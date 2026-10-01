import '../../../../core/money/money.dart';

/// One bar group on the profit trend: what sold in one day, week or month.
class TrendBucket {
  const TrendBucket({
    required this.start,
    required this.revenue,
    required this.profit,
  });

  /// The first instant of the bucket.
  final DateTime start;

  /// What buyers paid, refunds taken off. Zero is a fact here — nothing sold.
  final Money revenue;

  /// The sales' own profit, before overhead expenses.
  ///
  /// **Null when any sale in the bucket has no known profit** (no payout or
  /// no cost recorded). A bar summed over the known half would look like the
  /// whole bucket (hard rule 5), so the bucket draws revenue alone instead.
  final Money? profit;
}

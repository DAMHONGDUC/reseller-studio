import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../entities/order.dart';

/// What one marketplace still owes, and what it has already paid.
class MarketplacePayout {
  const MarketplacePayout({
    required this.marketplace,
    required this.settled,
    required this.awaiting,
    required this.settledTotal,
    required this.awaitingTotal,
    required this.awaitingIsEstimated,
  });

  final Marketplace marketplace;

  /// Orders whose payout the seller has recorded, newest first.
  final List<Order> settled;

  /// Orders that earned money and have no payout recorded, oldest first —
  /// the oldest is the one most likely to have been missed.
  final List<Order> awaiting;

  /// What the platform actually paid, summed. A fact, not a derivation.
  final Money? settledTotal;

  /// What it still owes, net of fees and the shipping the seller paid.
  final Money? awaitingTotal;

  /// Whether [awaitingTotal] leans on `Marketplace.estimatedFeeRate` for any
  /// order.
  ///
  /// **The UI must say so when this is true.** A figure a seller reconciles
  /// their bank against has to declare when part of it is a guess, or the
  /// first mismatch reads as a missing payment rather than a fee estimate.
  final bool awaitingIsEstimated;

  bool get isEmpty => settled.isEmpty && awaiting.isEmpty;
}

/// Which orders a marketplace has settled and which it still owes (plan §8).
///
/// **`Order.payout` is the only stored figure that is not derived** — it is a
/// fact the platform reported. This service is the other half: it says which
/// orders are still missing one, so a deposit that never arrived is visible
/// instead of being one blank field on a detail screen nobody reopens.
///
/// Pure, and it takes the rows rather than reading them: the interesting cases
/// are an order with no reported fee and a refund landing after settlement,
/// and a service that fetched its own data could not be tested at either.
final class PayoutReconciliation {
  /// One entry per marketplace that has an order worth money, busiest first.
  static List<MarketplacePayout> byMarketplace(List<Order> orders) {
    final Map<Marketplace, List<Order>> grouped = <Marketplace, List<Order>>{};

    for (final Order order in orders) {
      if (!order.status.countsAsRevenue) continue;

      grouped.putIfAbsent(order.marketplace, () => <Order>[]).add(order);
    }

    final List<MarketplacePayout> rows = grouped.entries
        .map(
          (MapEntry<Marketplace, List<Order>> entry) =>
              _payout(entry.key, entry.value),
        )
        .toList();

    return rows..sort(
      (MarketplacePayout a, MarketplacePayout b) =>
          b.awaiting.length.compareTo(a.awaiting.length),
    );
  }

  /// What one order should land in the bank as.
  ///
  /// Sale price, less anything refunded, less the platform's cut, less the
  /// postage the seller bought. **A missing fee falls back to
  /// `Marketplace.estimatedFeeRate`** rather than to zero: zero would claim
  /// the platform worked for free, which overstates every figure built on it.
  static Money expected(Order order) {
    final Money zero = Money.zero(order.salePrice.currency);
    final Money fees =
        order.fees ??
        order.salePrice.applyRate(order.marketplace.estimatedFeeRate);

    return order.salePrice -
        (order.refund ?? zero) -
        fees -
        (order.shippingCost ?? zero);
  }

  /// Whether [expected] had to guess this order's fee.
  static bool isEstimated(Order order) => order.fees == null;

  static MarketplacePayout _payout(
    Marketplace marketplace,
    List<Order> orders,
  ) {
    final List<Order> settled =
        orders.where((Order order) => order.payout != null).toList()
          ..sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));

    final List<Order> awaiting =
        orders.where((Order order) => order.payout == null).toList()
          ..sort((Order a, Order b) => a.orderedAt.compareTo(b.orderedAt));

    return MarketplacePayout(
      marketplace: marketplace,
      settled: settled,
      awaiting: awaiting,
      settledTotal: settled.map((Order order) => order.payout).totalOfKnown(),
      awaitingTotal: awaiting.map(expected).totalOrNull(),
      awaitingIsEstimated: awaiting.any(isEstimated),
    );
  }
}

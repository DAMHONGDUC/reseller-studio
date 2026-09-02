import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../entities/order.dart';

/// What one marketplace still owes, and what it has already paid.
class MarketplacePayout {
  const MarketplacePayout({
    required this.marketplaceId,
    required this.marketplaceName,
    required this.settled,
    required this.awaiting,
    required this.settledTotal,
    required this.awaitingTotal,
    required this.awaitingIsEstimated,
  });

  final String marketplaceId;
  final String marketplaceName;

  Marketplace get marketplace => Marketplace.values.firstWhere(
    (Marketplace value) => value.name == marketplaceId,
    orElse: () => Marketplace.other,
  );

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
  /// How long after posting a platform has to pay before it is worth chasing.
  ///
  /// Two weeks: past every platform's normal settlement window, so a run of
  /// these is a real gap and not the seller being impatient. **Mirrored
  /// deliberately in `functions/src/notifications/dailyDigest.ts`**, which
  /// sends the reminder — changing one means changing the other, the same
  /// arrangement `PlanLimits` and `ceilingsByPlan` have.
  static const int overdueAfterDays = 14;

  /// Sales a marketplace has still not paid for, long enough to chase.
  ///
  /// **Only orders that have actually shipped.** A platform owes nothing on a
  /// parcel still on the seller's table, and counting those would make the
  /// figure a complaint about the seller's own queue.
  static List<Order> overdue(List<Order> orders, DateTime now) {
    final DateTime cutoff = now.subtract(
      const Duration(days: overdueAfterDays),
    );

    return orders.where((Order order) {
      final DateTime? shipped = order.shippedAt;

      if (order.payout != null || shipped == null) return false;

      return order.status.countsAsRevenue && shipped.isBefore(cutoff);
    }).toList();
  }

  /// What those sales should have paid, summed.
  ///
  /// Null when there are none — hard rule 5: no outstanding payout is not
  /// the same claim as zero money owed.
  static Money? overdueTotal(
    List<Order> orders,
    DateTime now, {
    Map<String, double> feeRates = const <String, double>{},
  }) => overdue(orders, now)
      .map((Order order) => expected(order, feeRates: feeRates))
      .totalOrNull();

  /// One entry per marketplace that has an order worth money, busiest first.
  static List<MarketplacePayout> byMarketplace(
    List<Order> orders, {
    Map<String, double> feeRates = const <String, double>{},
  }) {
    final Map<String, List<Order>> grouped = <String, List<Order>>{};

    for (final Order order in orders) {
      if (!order.status.countsAsRevenue) continue;

      grouped.putIfAbsent(order.marketplaceId, () => <Order>[]).add(order);
    }

    final List<MarketplacePayout> rows = grouped.entries
        .map(
          (MapEntry<String, List<Order>> entry) =>
              _payout(entry.key, entry.value, feeRates),
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
  static Money expected(
    Order order, {
    Map<String, double> feeRates = const <String, double>{},
  }) {
    final Money zero = Money.zero(order.salePrice.currency);
    final Money fees = order.effectiveFees(feeRates);

    return order.salePrice -
        (order.refund ?? zero) -
        fees -
        (order.shippingCost ?? zero);
  }

  /// Whether [expected] had to guess this order's fee.
  static bool isEstimated(Order order) => order.feesAreEstimated;

  static MarketplacePayout _payout(
    String marketplaceId,
    List<Order> orders,
    Map<String, double> feeRates,
  ) {
    final List<Order> settled =
        orders.where((Order order) => order.payout != null).toList()
          ..sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));

    final List<Order> awaiting =
        orders.where((Order order) => order.payout == null).toList()
          ..sort((Order a, Order b) => a.orderedAt.compareTo(b.orderedAt));

    return MarketplacePayout(
      marketplaceId: marketplaceId,
      marketplaceName: orders.first.marketplaceName,
      settled: settled,
      awaiting: awaiting,
      settledTotal: settled.map((Order order) => order.payout).totalOfKnown(),
      awaitingTotal: awaiting
          .map((Order order) => expected(order, feeRates: feeRates))
          .totalOrNull(),
      awaitingIsEstimated: awaiting.any(isEstimated),
    );
  }
}

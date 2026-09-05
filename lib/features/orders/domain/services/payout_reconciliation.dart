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

  /// What it still owes, over the orders whose fee the seller has recorded.
  ///
  /// **Null when none of them has one** (hard rule 5), which is the normal
  /// state: nothing is estimated any more, so an outstanding order usually
  /// contributes a count rather than an amount.
  final Money? awaitingTotal;

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
  static Money? overdueTotal(List<Order> orders, DateTime now) =>
      overdue(orders, now).map(expected).totalOfKnown();

  /// One entry per marketplace that has an order worth money, busiest first.
  static List<MarketplacePayout> byMarketplace(List<Order> orders) {
    final Map<String, List<Order>> grouped = <String, List<Order>>{};

    for (final Order order in orders) {
      if (!order.status.countsAsRevenue) continue;

      grouped.putIfAbsent(order.marketplaceId, () => <Order>[]).add(order);
    }

    final List<MarketplacePayout> rows = grouped.entries
        .map(
          (MapEntry<String, List<Order>> entry) =>
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
  /// postage the seller bought.
  ///
  /// **Null when the cut is not known** (hard rule 3): the app stopped
  /// guessing a fee from a published rate, so an order nobody has recorded a
  /// payout or a fee for has no forecast — it has a prompt to go and read one
  /// off the platform.
  static Money? expected(Order order) {
    final Money? cut = order.platformFees;

    if (cut == null) return null;

    final Money zero = Money.zero(order.salePrice.currency);

    return order.salePrice -
        (order.refund ?? zero) -
        cut -
        (order.shippingCost ?? zero);
  }

  /// What a [payout] of this size says the platform kept.
  ///
  /// The inverse of [expected], and it lives here so the sheet that takes the
  /// figure and the statement that reads it back cannot derive it two ways.
  static Money feeImpliedBy(Order order, Money payout) {
    final Money zero = Money.zero(order.salePrice.currency);

    return order.salePrice -
        (order.refund ?? zero) -
        payout -
        (order.shippingCost ?? zero);
  }

  static MarketplacePayout _payout(String marketplaceId, List<Order> orders) {
    // One predicate for "still owed a figure", shared with the queue provider
    // — two spellings of it is how a card and a count come to disagree.
    final List<Order> settled =
        orders.where((Order order) => !order.needsPayout).toList()
          ..sort((Order a, Order b) => b.orderedAt.compareTo(a.orderedAt));

    final List<Order> awaiting =
        orders.where((Order order) => order.needsPayout).toList()
          ..sort((Order a, Order b) => a.orderedAt.compareTo(b.orderedAt));

    return MarketplacePayout(
      marketplaceId: marketplaceId,
      marketplaceName: orders.first.marketplaceName,
      settled: settled,
      awaiting: awaiting,
      settledTotal: settled.map((Order order) => order.payout).totalOfKnown(),
      awaitingTotal: awaiting.map(expected).totalOfKnown(),
    );
  }
}

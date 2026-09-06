import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/services/payout_reconciliation.dart';
import '../../../sourcing/domain/entities/purchase.dart';

/// Everywhere the books are still guessing.
///
/// **The em dashes and the estimates, gathered into one place.** Hard rule 5
/// makes the app say `—` rather than invent a number, and `Order.effectiveFees`
/// makes it label an estimate rather than present it as a fact — both are the
/// honest thing to do and neither is the end of the story. Somebody still has
/// to go and enter the figure, and until this existed there was no screen that
/// could say which figures those were.
///
/// It is what the tax export leans on: a summary is only as exact as the rows
/// under it, and "128 sales, 0 estimated" is the sentence that makes the
/// export worth handing to an accountant.
///
/// Pure, and it takes the rows rather than reading them — the interesting
/// cases are a business with nothing missing and one with a hole of every
/// kind, and a service that fetched its own data could be tested at neither.
class BookkeepingGaps {
  const BookkeepingGaps({
    required this.missingPayouts,
    required this.unknownCost,
    required this.unpaidPayouts,
    required this.receiptlessPurchases,
    required this.checkedOrders,
  });

  /// Sales where nobody has recorded what the platform paid, so the fee — and
  /// with it the profit — is unknown rather than approximate (hard rule 3).
  final List<Order> missingPayouts;

  /// Sales where an item's cost was never entered, so the profit is not an
  /// estimate at all — it is unknowable, and renders `—`.
  final List<Order> unknownCost;

  /// Sales a marketplace should have settled by now.
  final List<Order> unpaidPayouts;

  /// Buying trips with no receipt attached. The one gap that is not about a
  /// number: an expense with no document behind it is the one an accountant
  /// disallows.
  final List<Purchase> receiptlessPurchases;

  /// How many sales were looked at.
  ///
  /// The other half of the assurance line the tax export is worth handing
  /// over for: "0 estimated" means nothing without "out of 128".
  final int checkedOrders;

  /// Fold the rows.
  ///
  /// **Only orders whose money counts.** A cancelled sale has no fee worth
  /// chasing and a refunded one gave the money back, so listing either would
  /// send the seller to fix a record that is already correct.
  /// [from] and [toExclusive] narrow it to one filing period.
  ///
  /// **Both null is the whole business**, which is what the Close the books
  /// screen wants. The tax export wants the year it is about to hand over and
  /// nothing else: a gap in a year already filed is not work this return is
  /// waiting on.
  factory BookkeepingGaps.from({
    required List<Order> orders,
    required List<Purchase> purchases,
    required DateTime now,
    DateTime? from,
    DateTime? toExclusive,
  }) {
    bool within(DateTime when) =>
        (from == null || !when.isBefore(from)) &&
        (toExclusive == null || when.isBefore(toExclusive));

    final List<Order> counted = orders
        .where(
          (Order order) =>
              order.status.countsAsRevenue && within(order.orderedAt),
        )
        .toList();

    return BookkeepingGaps(
      checkedOrders: counted.length,
      missingPayouts: counted
          .where((Order order) => order.needsPayout)
          .toList(),
      unknownCost: counted
          .where((Order order) => order.costOfGoods == null)
          .toList(),
      unpaidPayouts: PayoutReconciliation.overdue(
        orders.where((Order order) => within(order.orderedAt)).toList(),
        now,
      ),
      receiptlessPurchases: purchases
          .where(
            (Purchase purchase) =>
                !purchase.isDeleted &&
                purchase.receiptUrl == null &&
                within(purchase.purchaseDate),
          )
          .toList(),
    );
  }

  /// How many records need a figure before the books are exact.
  ///
  /// **A sale can be counted twice** — one missing both its fee and its cost
  /// is two pieces of work, and rolling it into one would understate what is
  /// left to do.
  int get total =>
      missingPayouts.length +
      unknownCost.length +
      unpaidPayouts.length +
      receiptlessPurchases.length;

  bool get isClear => total == 0;
}

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
    required this.estimatedFees,
    required this.unknownCost,
    required this.unpaidPayouts,
    required this.receiptlessPurchases,
  });

  /// Sales where nobody entered what the platform actually charged, so the
  /// profit is the published rate rather than the real one.
  final List<Order> estimatedFees;

  /// Sales where an item's cost was never entered, so the profit is not an
  /// estimate at all — it is unknowable, and renders `—`.
  final List<Order> unknownCost;

  /// Sales a marketplace should have settled by now.
  final List<Order> unpaidPayouts;

  /// Buying trips with no receipt attached. The one gap that is not about a
  /// number: an expense with no document behind it is the one an accountant
  /// disallows.
  final List<Purchase> receiptlessPurchases;

  /// Fold the rows.
  ///
  /// **Only orders whose money counts.** A cancelled sale has no fee worth
  /// chasing and a refunded one gave the money back, so listing either would
  /// send the seller to fix a record that is already correct.
  factory BookkeepingGaps.from({
    required List<Order> orders,
    required List<Purchase> purchases,
    required DateTime now,
  }) {
    final List<Order> counted = orders
        .where((Order order) => order.status.countsAsRevenue)
        .toList();

    return BookkeepingGaps(
      estimatedFees: counted
          .where((Order order) => order.feesAreEstimated)
          .toList(),
      unknownCost: counted
          .where((Order order) => order.costOfGoods == null)
          .toList(),
      unpaidPayouts: PayoutReconciliation.overdue(orders, now),
      receiptlessPurchases: purchases
          .where(
            (Purchase purchase) =>
                !purchase.isDeleted && purchase.receiptUrl == null,
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
      estimatedFees.length +
      unknownCost.length +
      unpaidPayouts.length +
      receiptlessPurchases.length;

  bool get isClear => total == 0;
}

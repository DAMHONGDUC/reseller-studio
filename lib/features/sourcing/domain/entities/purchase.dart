import '../../../../core/money/money.dart';

/// A buying trip — one visit to one source, and everything bought there.
///
/// **[totalCost] is stored rather than derived, and it is the one place in
/// this app that bends hard rule 3.** The reason is that a purchase's real
/// total and the sum of its items' costs legitimately disagree: a $40 box lot
/// yields eleven items, and the seller apportions the cost across them by
/// judgement. The receipt says $40; the items may sum to $38 because two were
/// written off. Deriving the total would silently rewrite what the seller
/// actually paid.
///
/// So: [totalCost] is what left the seller's pocket, and item costs are the
/// apportionment. The Purchase detail screen shows both and flags the gap
/// rather than hiding it.
class Purchase {
  const Purchase({
    required this.id,
    required this.purchaseDate,
    required this.createdAt,
    this.sourceId,
    this.totalCost,
    this.receiptUrl,
    this.notes,
    this.itemCount = 0,
    this.deletedAt,
  });

  final String id;

  /// Required (plan §28) — a purchase with no date cannot be placed in any
  /// report, and every tax summary is built by period.
  final DateTime purchaseDate;

  final DateTime createdAt;

  /// Optional: a seller may record what they bought before recording where.
  final String? sourceId;

  /// What was actually paid, from the receipt. Null when not yet entered.
  final Money? totalCost;

  final String? receiptUrl;
  final String? notes;

  /// Denormalised count of the items linked to this purchase, so the
  /// Purchases list does not fan out a query per row.
  final int itemCount;

  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// A copy with a different item count.
  ///
  /// The only field anything recomputes — `PurchaseItemCount` owns the rule,
  /// and everything else on a purchase is typed by the seller.
  Purchase copyWith({int? itemCount}) => Purchase(
    id: id,
    purchaseDate: purchaseDate,
    createdAt: createdAt,
    sourceId: sourceId,
    totalCost: totalCost,
    receiptUrl: receiptUrl,
    notes: notes,
    itemCount: itemCount ?? this.itemCount,
    deletedAt: deletedAt,
  );
}

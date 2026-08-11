import '../../../../core/money/money.dart';
import '../../../listings/domain/enums/listing_status.dart';

/// A business cost that is not the cost of an item (plan §17).
///
/// Kept separate from `Item.purchasePrice` on purpose: an item's cost is
/// attributable to a specific sale, whereas packaging tape and storage rent
/// are overheads that reduce profit without belonging to any one order. Both
/// feed the profit statement, at different lines.
class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.vendor,
    this.notes,
    this.receiptUrl,
    this.mileage,
    this.orderId,
    this.isRecurring = false,
    this.deletedAt,
  });

  final String id;

  /// Required (plan §28) — an uncategorised expense cannot appear in a tax
  /// report, which is most of why the feature exists.
  final ExpenseCategory category;

  final Money amount;
  final DateTime date;
  final DateTime createdAt;
  final String? vendor;
  final String? notes;
  final String? receiptUrl;

  /// Distance driven, for a `mileage` expense. Kept as a number rather than
  /// folded into [amount] because the deductible rate per mile is set by the
  /// tax authority and changes yearly — storing only the money would freeze
  /// last year's rate into the record.
  final double? mileage;

  /// Set when this cost belongs to one sale — a shipping label, say. Null for
  /// a general overhead. What lets `Order.profit` take an `otherExpenses`.
  final String? orderId;

  final bool isRecurring;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}

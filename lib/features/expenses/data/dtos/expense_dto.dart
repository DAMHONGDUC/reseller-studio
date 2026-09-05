import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/money/money.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/entities/expense.dart';

/// How an [Expense] is stored.
///
/// `orderId` is set when the cost belongs to one sale — a shipping label —
/// and null for a general overhead. Analytics counts only the overheads, so
/// a label already inside an order's shipping cost is not deducted twice.
final class ExpenseDto {
  static Expense toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return Expense(
      id: WorkspaceTable.localId(doc.id),
      category:
          FirestoreMapper.enumOrNull(
            ExpenseCategory.values,
            data['categoryId'],
          ) ??
          ExpenseCategory.other,
      amount:
          FirestoreMapper.moneyOrNull(data['amountMinor'], currency) ??
          Money.zero(currency),
      date: FirestoreMapper.dateOr(data['date'], DateTime.now()),
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      vendor: FirestoreMapper.stringOrNull(data['vendor']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
      receiptUrl: FirestoreMapper.stringOrNull(data['receiptUrl']),
      mileage: FirestoreMapper.doubleOrNull(data['mileage']),
      orderId: FirestoreMapper.stringOrNull(data['orderId']),
      isRecurring: FirestoreMapper.boolOr(data['isRecurring'], fallback: false),
      recurringSeriesId: FirestoreMapper.stringOrNull(
        data['recurringSeriesId'],
      ),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Expense expense, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'categoryId': expense.category.name,
    'currency': expense.amount.currency,
    'amountMinor': expense.amount.minor,
    'date': Timestamp.fromDate(expense.date),
    'vendor': expense.vendor,
    'notes': expense.notes,
    'receiptUrl': expense.receiptUrl,
    // Kept as a distance rather than folded into the amount: the deductible
    // rate per mile is set by the tax authority and changes yearly.
    'mileage': expense.mileage,
    'orderId': expense.orderId,
    'isRecurring': expense.isRecurring,
    // Points at the first occurrence. Null on the first one itself, and on
    // anything written before the field existed — `Expense.seriesId` reads
    // both as their own series.
    'recurringSeriesId': expense.recurringSeriesId,
    'deletedAt': expense.deletedAt == null
        ? null
        : Timestamp.fromDate(expense.deletedAt!),
    'createdAt': Timestamp.fromDate(expense.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}

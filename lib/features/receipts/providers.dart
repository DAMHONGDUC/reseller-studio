/// Riverpod wiring for `receipts` (plan §18).
///
/// **There is no `receipts` collection and no `Receipt` entity.** A receipt is
/// a file attached to a record that already exists — a purchase or an expense
/// — and both already carry a `receiptUrl`. A second source of truth would
/// mean two places that can disagree about whether a purchase has its receipt,
/// and a document that outlives the thing it was a receipt for.
///
/// So this feature is a *view*: it folds the records that have a document into
/// one list, which is the question plan §18 actually asks — "where is the
/// paperwork".
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../expenses/domain/entities/expense.dart';
import '../expenses/providers.dart';
import '../sourcing/domain/entities/purchase.dart';
import '../sourcing/providers.dart';

/// What a stored document belongs to.
enum ReceiptKind { purchase, expense }

/// One piece of paperwork, wherever it is attached.
class ReceiptEntry {
  const ReceiptEntry({
    required this.kind,
    required this.recordId,
    required this.url,
    required this.date,
    required this.title,
    this.amount,
  });

  final ReceiptKind kind;

  /// The purchase or expense this is attached to — what a tap opens.
  final String recordId;

  final String url;
  final DateTime date;
  final String title;

  /// Null when the record never recorded one. `—`, never zero (hard rule 5).
  final Money? amount;
}

/// Every document in the workspace, newest first.
final Provider<List<ReceiptEntry>> receiptsProvider =
    Provider<List<ReceiptEntry>>((Ref ref) {
      final List<Purchase> purchases =
          ref.watch(purchasesProvider).value ?? const <Purchase>[];
      final List<Expense> expenses =
          ref.watch(expensesProvider).value ?? const <Expense>[];
      final Map<String, String> sourceNames = ref.watch(sourceNamesProvider);

      final List<ReceiptEntry> entries = <ReceiptEntry>[
        for (final Purchase purchase in purchases)
          if (purchase.receiptUrl != null)
            ReceiptEntry(
              kind: ReceiptKind.purchase,
              recordId: purchase.id,
              url: purchase.receiptUrl!,
              date: purchase.purchaseDate,
              title: sourceNames[purchase.sourceId] ?? 'Purchase',
              amount: purchase.totalCost,
            ),
        for (final Expense expense in expenses)
          if (expense.receiptUrl != null)
            ReceiptEntry(
              kind: ReceiptKind.expense,
              recordId: expense.id,
              url: expense.receiptUrl!,
              date: expense.date,
              title: expense.vendor ?? 'Expense',
              amount: expense.amount,
            ),
      ]..sort(
        (ReceiptEntry a, ReceiptEntry b) => b.date.compareTo(a.date),
      );

      return entries;
    });

/// How many records still have no document attached.
///
/// The number a seller wants before a tax deadline: not "how many receipts do
/// I have" but "how many am I missing".
final Provider<int> missingReceiptCountProvider = Provider<int>((Ref ref) {
  final List<Purchase> purchases =
      ref.watch(purchasesProvider).value ?? const <Purchase>[];
  final List<Expense> expenses =
      ref.watch(expensesProvider).value ?? const <Expense>[];

  return purchases
          .where((Purchase purchase) => purchase.receiptUrl == null)
          .length +
      expenses.where((Expense expense) => expense.receiptUrl == null).length;
});

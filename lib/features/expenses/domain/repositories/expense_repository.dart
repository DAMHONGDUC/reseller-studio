import '../entities/expense.dart';

/// Reading and writing expenses.
abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchExpenses();

  /// Expenses attributed to one order — what `Order.profit` takes as its
  /// `otherExpenses`, looked up here rather than by the entity, since an
  /// entity never reaches into a repository.
  Stream<List<Expense>> watchExpensesForOrder(String orderId);

  Future<void> save(Expense expense);

  Future<void> delete(String id);
}

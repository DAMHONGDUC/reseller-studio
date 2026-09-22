import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../dtos/expense_dto.dart';

/// Expenses, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalExpenseRepository implements ExpenseRepository {
  LocalExpenseRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<Expense>(
        table: LocalTable(db, db.localExpenses),
        fromMap: (String id, Map<String, Object?> data) =>
            ExpenseDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Expense expense) =>
            ExpenseDto.toMap(expense, createdBy: GuestConstant.uid),
        idOf: (Expense expense) => expense.id,
        // Ordered by the date the money moved, not the date it was typed in —
        // the same column `FirestoreExpenseRepository` sorts on.
        createdAtOf: (Expense expense) => expense.date,
        isDeleted: (Expense expense) => expense.isDeleted,
        logTag: LogTagConstant.expense,
        label: 'expense',
      );

  final LocalCollection<Expense> _collection;

  @override
  Stream<List<Expense>> watchExpenses() => _collection.watchAll();

  @override
  Stream<List<Expense>> watchExpensesForOrder(String orderId) =>
      _collection.watchWhere((Expense expense) => expense.orderId == orderId);

  @override
  Future<void> save(Expense expense) => _collection.save(expense);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}

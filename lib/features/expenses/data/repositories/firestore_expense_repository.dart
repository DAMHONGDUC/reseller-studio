import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../dtos/expense_dto.dart';

/// Expenses, in Firestore.
class FirestoreExpenseRepository implements ExpenseRepository {
  const FirestoreExpenseRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Expense>> watchExpenses() => FirestoreStream.collection(
    _context.collections.expenses.orderBy('date', descending: true),
    _toEntity,
    operation: 'load expenses',
  ).map(_live);

  @override
  Stream<List<Expense>> watchExpensesForOrder(String orderId) =>
      FirestoreStream.collection(
        _context.collections.expenses.where('orderId', isEqualTo: orderId),
        _toEntity,
        operation: 'load expenses for order',
      ).map(_live);

  @override
  Future<void> save(Expense expense) =>
      FailureMapper.guard('save expense', () async {
        await _context.collections.expenses
            .doc(expense.id)
            .set(
              ExpenseDto.toMap(expense, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        AppLogger.info('Expense saved', <String, Object>{
          'expenseId': expense.id,
          'category': expense.category.name,
        });
      });

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete expense', () async {
        await _context.collections.expenses.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.info('Expense soft-deleted', <String, Object>{
          'expenseId': id,
        });
      });

  Expense _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      ExpenseDto.toEntity(doc, fallbackCurrency: _context.currency);

  static List<Expense> _live(List<Expense> expenses) =>
      expenses.where((Expense expense) => !expense.isDeleted).toList();
}

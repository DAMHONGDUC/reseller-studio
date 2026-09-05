import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../dtos/expense_dto.dart';

/// Expenses, in Firestore.
class FirestoreExpenseRepository implements ExpenseRepository {
  const FirestoreExpenseRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Expense>> watchExpenses() => FirestoreStream.collection(
    _context.collections.expenses.query.orderBy('date', descending: true),
    _toEntity,
    operation: 'load expenses',
  ).map(_live);

  @override
  Stream<List<Expense>> watchExpensesForOrder(String orderId) =>
      FirestoreStream.collection(
        _context.collections.expenses.query.where(
          'orderId',
          isEqualTo: orderId,
        ),
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

        SdLogger.info(LogTagConstant.expense, 'Expense saved', <String, Object>{
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

        SdLogger.info(
          LogTagConstant.expense,
          'Expense soft-deleted',
          <String, Object>{'expenseId': id},
        );
      });

  Expense _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      ExpenseDto.toEntity(doc, fallbackCurrency: _context.currency);

  static List<Expense> _live(List<Expense> expenses) =>
      expenses.where((Expense expense) => !expense.isDeleted).toList();
}

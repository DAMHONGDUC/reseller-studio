/// Riverpod wiring for `expenses`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/time/app_clock.dart';
import '../listings/domain/enums/listing_status.dart';
import '../workspace/providers.dart';
import 'domain/entities/expense.dart';
import 'domain/services/recurring_expense_schedule.dart';

final StreamProvider<List<Expense>> expensesProvider =
    StreamProvider<List<Expense>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Expense>(
        ref,
        () => ref.watch(expenseRepositoryProvider).watchExpenses(),
      );
    });

/// Costs attributed to one sale — a shipping label, the packaging for it.
///
/// What `Order.profit` takes as its `otherExpenses`. Looked up here rather
/// than by the entity, since an entity never reaches into a repository.
// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final expensesForOrderProvider = StreamProvider.family<List<Expense>, String>((
  Ref ref,
  String orderId,
) {
  return WorkspaceGuard.listOrEmpty<Expense>(
    ref,
    () => ref.watch(expenseRepositoryProvider).watchExpensesForOrder(orderId),
  );
});

/// What each category has cost over every recorded expense.
///
/// Ordered by spend, biggest first — the question this answers is "where is
/// the money going", and alphabetical order answers a question nobody asked.
final Provider<List<MapEntry<ExpenseCategory, Money>>>
expenseTotalsByCategoryProvider =
    Provider<List<MapEntry<ExpenseCategory, Money>>>((Ref ref) {
      final List<Expense> expenses =
          ref.watch(expensesProvider).value ?? const <Expense>[];
      final Map<ExpenseCategory, Money> totals = <ExpenseCategory, Money>{};

      for (final Expense expense in expenses) {
        final Money? running = totals[expense.category];

        totals[expense.category] = running == null
            ? expense.amount
            : running + expense.amount;
      }

      final List<MapEntry<ExpenseCategory, Money>> rows =
          totals.entries.toList()..sort(
            (
              MapEntry<ExpenseCategory, Money> a,
              MapEntry<ExpenseCategory, Money> b,
            ) => b.value.compareTo(a.value),
          );

      return rows;
    });

/// The recurring costs that are owed today.
///
/// Reads [clockProvider] rather than `DateTime.now()`: "due" is derived, so a
/// test pins it and the same assertion cannot pass in one month and fail in
/// the next.
final Provider<List<RecurringExpense>> dueRecurringExpensesProvider =
    Provider<List<RecurringExpense>>((Ref ref) {
      return RecurringExpenseSchedule.due(
        expenses: ref.watch(expensesProvider).value ?? const <Expense>[],
        now: ref.watch(clockProvider).now(),
      );
    });

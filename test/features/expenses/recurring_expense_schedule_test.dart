import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/expenses/domain/entities/expense.dart';
import 'package:reseller_studio/features/expenses/domain/services/recurring_expense_schedule.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';

/// A month boundary and a series with several occurrences are the only
/// interesting cases here, so every row is placed against one.
void main() {
  Expense expense(
    String id,
    DateTime date, {
    bool isRecurring = true,
    String? seriesId,
    int minor = 5000,
    DateTime? deletedAt,
  }) => Expense(
    id: id,
    category: ExpenseCategory.storage,
    amount: Money(minor, 'GBP'),
    date: date,
    createdAt: date,
    isRecurring: isRecurring,
    recurringSeriesId: seriesId,
    deletedAt: deletedAt,
  );

  test('a series is owed one month after its latest occurrence', () {
    final List<RecurringExpense> due = RecurringExpenseSchedule.due(
      expenses: <Expense>[expense('exp-1', DateTime(2026, 7, 3))],
      now: DateTime(2026, 8, 3),
    );

    expect(due, hasLength(1));
    expect(due.single.due, DateTime(2026, 8, 3));
    expect(due.single.seriesId, 'exp-1');
  });

  test('it is not owed yet the day before', () {
    expect(
      RecurringExpenseSchedule.due(
        expenses: <Expense>[expense('exp-1', DateTime(2026, 7, 3))],
        now: DateTime(2026, 8, 2),
      ),
      isEmpty,
    );
  });

  test('the newest occurrence is what the next one is copied from', () {
    // A rent rise recorded in July has to carry forward, not the June price.
    final List<RecurringExpense> due = RecurringExpenseSchedule.due(
      expenses: <Expense>[
        expense('exp-1', DateTime(2026, 6, 3)),
        expense('exp-2', DateTime(2026, 7, 3), seriesId: 'exp-1', minor: 6000),
      ],
      now: DateTime(2026, 9, 1),
    );

    expect(due, hasLength(1));
    expect(due.single.latest.id, 'exp-2');
    expect(due.single.latest.amount.minor, 6000);
  });

  test('deleting the occurrence you posted by mistake owes the month again', () {
    final List<RecurringExpense> due = RecurringExpenseSchedule.due(
      expenses: <Expense>[
        expense('exp-1', DateTime(2026, 6, 3)),
        expense(
          'exp-2',
          DateTime(2026, 7, 3),
          seriesId: 'exp-1',
          deletedAt: DateTime(2026, 7, 4),
        ),
      ],
      now: DateTime(2026, 7, 10),
    );

    expect(due.single.latest.id, 'exp-1');
    expect(due.single.due, DateTime(2026, 7, 3));
  });

  test('a one-off cost is never a series', () {
    expect(
      RecurringExpenseSchedule.due(
        expenses: <Expense>[
          expense('exp-1', DateTime(2026, 1, 3), isRecurring: false),
        ],
        now: DateTime(2027, 1, 1),
      ),
      isEmpty,
    );
  });

  test('a shorter month clamps rather than spilling into the next', () {
    final List<RecurringExpense> due = RecurringExpenseSchedule.due(
      expenses: <Expense>[expense('exp-1', DateTime(2027, 1, 31))],
      now: DateTime(2027, 3, 1),
    );

    expect(due.single.due, DateTime(2027, 2, 28));
  });
}

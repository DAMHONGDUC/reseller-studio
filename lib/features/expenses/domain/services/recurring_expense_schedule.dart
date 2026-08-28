import '../../../../core/utils/date_time_utils.dart';
import '../entities/expense.dart';

/// One recurring cost, and when it is next owed.
class RecurringExpense {
  const RecurringExpense({required this.latest, required this.due});

  /// The most recent occurrence — what the next one is copied from, so a rent
  /// rise recorded last month carries forward rather than the original price.
  final Expense latest;

  /// The date the next occurrence falls on. In the past when it is overdue.
  final DateTime due;

  String get seriesId => latest.seriesId;
}

/// Which recurring costs are owed, and from what.
///
/// **It proposes; it never posts** — `docs/rules/DECISIONS.md` § A recurring
/// expense is proposed, never posted on its own. An expense is a tax record,
/// and storage rent cancelled in March that keeps posting in April is a wrong
/// figure nobody finds until it is on a return.
///
/// Pure, and it takes the rows rather than reading them: the interesting cases
/// are a month boundary and a series whose latest occurrence is old, and a
/// service that fetched its own data could not be tested at either.
final class RecurringExpenseSchedule {
  /// How often a recurring expense recurs.
  ///
  /// Monthly is the only cadence, and the form says so. A second one becomes a
  /// field on the series, never an `if` here.
  static const int intervalMonths = 1;

  /// The series that are due on or before [now], oldest first.
  ///
  /// Oldest first because that is the order they are owed in, and a seller
  /// catching up after a month away wants to work down the list rather than
  /// hunt for which is furthest behind.
  static List<RecurringExpense> due({
    required List<Expense> expenses,
    required DateTime now,
  }) {
    final List<RecurringExpense> owed = all(
      expenses: expenses,
    ).where((RecurringExpense series) => !series.due.isAfter(now)).toList();

    return owed..sort(
      (RecurringExpense a, RecurringExpense b) => a.due.compareTo(b.due),
    );
  }

  /// Every recurring series, due or not, one entry per series.
  ///
  /// A deleted occurrence is dropped before the latest is chosen, so removing
  /// the copy you posted by mistake makes the month owed again rather than
  /// leaving the series stuck a month ahead.
  static List<RecurringExpense> all({required List<Expense> expenses}) {
    final Map<String, Expense> latest = <String, Expense>{};

    for (final Expense expense in expenses) {
      if (!expense.isRecurring || expense.isDeleted) continue;

      final Expense? running = latest[expense.seriesId];

      if (running == null || expense.date.isAfter(running.date)) {
        latest[expense.seriesId] = expense;
      }
    }

    return latest.values
        .map(
          (Expense expense) => RecurringExpense(
            latest: expense,
            due: DateTimeUtils.monthsAfter(expense.date, intervalMonths),
          ),
        )
        .toList();
  }
}

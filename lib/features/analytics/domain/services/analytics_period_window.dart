import '../../../../core/utils/date_time_utils.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../orders/domain/entities/order.dart';
import '../enums/analytics_period.dart';

/// Which records fall inside an [AnalyticsPeriod], counted back from now.
///
/// **Calendar days, today included.** "Last 7 days" on a Wednesday starts at
/// last Thursday's midnight, so a sale this morning and one a week ago today
/// are never both in or both out depending on the hour.
final class AnalyticsPeriodWindow {
  /// The first instant counted, or null for all time.
  static DateTime? startOf(AnalyticsPeriod period, DateTime now) {
    final DateTime today = DateTimeUtils.startOfDay(now);

    return switch (period) {
      AnalyticsPeriod.all => null,
      AnalyticsPeriod.days7 => DateTimeUtils.daysBefore(today, 6),
      AnalyticsPeriod.days30 => DateTimeUtils.daysBefore(today, 29),
      AnalyticsPeriod.days90 => DateTimeUtils.daysBefore(today, 89),
      AnalyticsPeriod.yearToDate => DateTimeUtils.startOfYear(now),
    };
  }

  /// Days for a week, weeks for a month or a quarter, months beyond that.
  static TrendGrain grainOf(AnalyticsPeriod period) => switch (period) {
    AnalyticsPeriod.days7 => TrendGrain.day,
    AnalyticsPeriod.days30 || AnalyticsPeriod.days90 => TrendGrain.week,
    AnalyticsPeriod.yearToDate || AnalyticsPeriod.all => TrendGrain.month,
  };

  /// Orders placed on or after [start]; every order when it is null.
  static List<Order> orders(List<Order> orders, DateTime? start) => orders
      .where((Order order) => DateTimeUtils.isWithin(order.orderedAt, from: start))
      .toList();

  /// Expenses dated on or after [start]; every expense when it is null.
  static List<Expense> expenses(List<Expense> expenses, DateTime? start) =>
      expenses
          .where(
            (Expense expense) =>
                DateTimeUtils.isWithin(expense.date, from: start),
          )
          .toList();
}

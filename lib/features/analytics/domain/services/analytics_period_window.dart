import '../../../../core/utils/date_time_utils.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../orders/domain/entities/order.dart';
import '../../analytics_period_constant.dart';
import '../entities/analytics_date_range.dart';
import '../enums/analytics_period.dart';

/// Which records fall inside an [AnalyticsPeriod], counted back from now.
///
/// **Calendar days, today included.** "Last 7 days" on a Wednesday starts at
/// last Thursday's midnight, so a sale this morning and one a week ago today
/// are never both in or both out depending on the hour.
final class AnalyticsPeriodWindow {
  /// The first instant counted, or null for all time.
  static DateTime? startOf(
    AnalyticsPeriod period,
    DateTime now, {
    AnalyticsDateRange? custom,
  }) {
    final DateTime today = DateTimeUtils.startOfDay(now);

    return switch (period) {
      // A Custom period with no range picked yet reads as all time.
      AnalyticsPeriod.custom =>
        custom == null ? null : DateTimeUtils.startOfDay(custom.from),
      AnalyticsPeriod.all => null,
      AnalyticsPeriod.days7 => DateTimeUtils.daysBefore(today, 6),
      AnalyticsPeriod.days30 => DateTimeUtils.daysBefore(today, 29),
      AnalyticsPeriod.days90 => DateTimeUtils.daysBefore(today, 89),
      AnalyticsPeriod.yearToDate => DateTimeUtils.startOfYear(now),
    };
  }

  /// Days for a week, weeks for a month or a quarter, months beyond that.
  /// Where the window stops, exclusive — the day after a Custom range's last
  /// day, and nothing for the rolling periods, which run to now.
  static DateTime? endOf(
    AnalyticsPeriod period, {
    AnalyticsDateRange? custom,
  }) => period == AnalyticsPeriod.custom && custom != null
      ? DateTimeUtils.daysAfter(DateTimeUtils.startOfDay(custom.to), 1)
      : null;

  static TrendGrain grainOf(
    AnalyticsPeriod period, {
    AnalyticsDateRange? custom,
  }) => switch (period) {
    AnalyticsPeriod.custom => _grainOfSpan(custom),
    AnalyticsPeriod.days7 => TrendGrain.day,
    AnalyticsPeriod.days30 || AnalyticsPeriod.days90 => TrendGrain.week,
    AnalyticsPeriod.yearToDate || AnalyticsPeriod.all => TrendGrain.month,
  };

  /// Orders placed in `[start, end)`; an open end on either side is unbounded.
  static List<Order> orders(
    List<Order> orders,
    DateTime? start, {
    DateTime? end,
  }) => orders
      .where(
        (Order order) =>
            DateTimeUtils.isWithin(order.orderedAt, from: start, to: end),
      )
      .toList();

  /// Expenses dated in `[start, end)`; an open end is unbounded.
  static List<Expense> expenses(
    List<Expense> expenses,
    DateTime? start, {
    DateTime? end,
  }) => expenses
      .where(
        (Expense expense) =>
            DateTimeUtils.isWithin(expense.date, from: start, to: end),
      )
      .toList();

  /// A day per bar across a fortnight, a week per bar across a season, and a
  /// month beyond — the same steps the fixed periods take.
  static TrendGrain _grainOfSpan(AnalyticsDateRange? range) {
    if (range == null) return TrendGrain.month;

    final int days = DateTimeUtils.daysBetween(range.from, range.to) + 1;

    if (days <= AnalyticsPeriodConstant.dayGrainMaxDays) return TrendGrain.day;
    if (days <= AnalyticsPeriodConstant.weekGrainMaxDays) {
      return TrendGrain.week;
    }

    return TrendGrain.month;
  }
}

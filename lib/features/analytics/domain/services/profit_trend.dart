import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/trend_bucket.dart';
import '../enums/analytics_period.dart';

/// Revenue and profit bucketed over time, derived on read (hard rule 3).
///
/// - buckets run from the period's start (or the first sale, for all time)
///   up to the one holding now, empty ones included — a week with no sales
///   is part of the story
/// - only revenue-counting orders, the same set the summary counts
final class ProfitTrend {
  /// Past a dozen bars the labels collide on a phone; older buckets drop off
  /// the front rather than every bar thinning out.
  static const int maxBuckets = 12;

  static List<TrendBucket> build({
    required List<Order> orders,
    required DateTime? start,
    required DateTime now,
    required TrendGrain grain,
    required String currency,
  }) {
    final List<Order> counted = orders
        .where(
          (Order order) =>
              order.status.countsAsRevenue &&
              DateTimeUtils.isWithin(order.orderedAt, from: start),
        )
        .toList();
    final DateTime? earliest = counted.isEmpty
        ? null
        : counted
              .map((Order order) => order.orderedAt)
              .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);

    if (earliest == null) return const <TrendBucket>[];

    final List<DateTime> starts = _starts(
      bucketStart(start ?? earliest, grain),
      bucketStart(now, grain),
      grain,
    );

    return starts
        .skip(starts.length > maxBuckets ? starts.length - maxBuckets : 0)
        .map(
          (DateTime from) => _bucket(
            counted
                .where(
                  (Order order) => DateTimeUtils.isWithin(
                    order.orderedAt,
                    from: from,
                    to: _next(from, grain),
                  ),
                )
                .toList(),
            from,
            currency,
          ),
        )
        .toList();
  }

  /// The start of the bucket holding [value].
  static DateTime bucketStart(DateTime value, TrendGrain grain) =>
      switch (grain) {
        TrendGrain.day => DateTimeUtils.startOfDay(value),
        TrendGrain.week => DateTimeUtils.startOfWeek(value),
        TrendGrain.month => DateTimeUtils.startOfMonth(value),
      };

  /// Every bucket start from [first] through [last], in order.
  static List<DateTime> _starts(
    DateTime first,
    DateTime last,
    TrendGrain grain,
  ) {
    final List<DateTime> starts = <DateTime>[];
    DateTime cursor = first;

    while (!cursor.isAfter(last)) {
      starts.add(cursor);
      cursor = _next(cursor, grain);
    }

    return starts;
  }

  static DateTime _next(DateTime from, TrendGrain grain) => switch (grain) {
    TrendGrain.day => DateTimeUtils.daysAfter(from, 1),
    TrendGrain.week => DateTimeUtils.daysAfter(from, 7),
    TrendGrain.month => DateTimeUtils.monthsAfter(from, 1),
  };

  static TrendBucket _bucket(
    List<Order> orders,
    DateTime start,
    String currency,
  ) {
    final Money zero = Money.zero(currency);
    final List<Money?> profits = orders
        .map((Order order) => order.profit().netProfit)
        .toList();

    return TrendBucket(
      start: start,
      revenue: orders
          .map((Order order) => order.salePrice - (order.refund ?? zero))
          .fold(zero, (Money sum, Money one) => sum + one),
      profit: profits.contains(null)
          ? null
          : profits.whereType<Money>().fold<Money>(
              zero,
              (Money sum, Money one) => sum + one,
            ),
    );
  }
}

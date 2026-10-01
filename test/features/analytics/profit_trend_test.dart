import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/analytics/domain/entities/trend_bucket.dart';
import 'package:reseller_studio/features/analytics/domain/enums/analytics_period.dart';
import 'package:reseller_studio/features/analytics/domain/services/analytics_period_window.dart';
import 'package:reseller_studio/features/analytics/domain/services/profit_trend.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// The period window and the trend chart's buckets, derived on read.
void main() {
  late List<Order> orders;

  setUpAll(() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    orders = container.read(ordersProvider).value!;
  });

  List<TrendBucket> trend(AnalyticsPeriod period, {List<Order>? from}) =>
      ProfitTrend.build(
        orders: from ?? orders,
        start: AnalyticsPeriodWindow.startOf(period, testNow),
        now: testNow,
        grain: AnalyticsPeriodWindow.grainOf(period),
        currency: 'USD',
      );

  group('the window', () {
    test('counts calendar days back, today included', () {
      // testNow is Wednesday 12 Aug 2026.
      expect(
        AnalyticsPeriodWindow.startOf(AnalyticsPeriod.days7, testNow),
        DateTime(2026, 8, 6),
      );
      expect(
        AnalyticsPeriodWindow.startOf(AnalyticsPeriod.days30, testNow),
        DateTime(2026, 7, 14),
      );
      expect(
        AnalyticsPeriodWindow.startOf(AnalyticsPeriod.yearToDate, testNow),
        DateTime(2026),
      );
      expect(
        AnalyticsPeriodWindow.startOf(AnalyticsPeriod.all, testNow),
        isNull,
      );
    });

    test('drops orders placed before the start', () {
      final DateTime start = AnalyticsPeriodWindow.startOf(
        AnalyticsPeriod.days7,
        testNow,
      )!;

      expect(
        AnalyticsPeriodWindow.orders(
          orders,
          start,
        ).every((Order order) => !order.orderedAt.isBefore(start)),
        isTrue,
      );
      expect(
        AnalyticsPeriodWindow.orders(orders, null),
        hasLength(orders.length),
      );
    });
  });

  group('the buckets', () {
    test('seven days is seven daily buckets, empty days included', () {
      final List<TrendBucket> buckets = trend(AnalyticsPeriod.days7);

      expect(buckets, hasLength(7));
      expect(buckets.first.start, DateTime(2026, 8, 6));
      expect(buckets.last.start, DateTime(2026, 8, 12));
      // A day with nothing sold is a fact, so its revenue is zero, not null.
      expect(
        buckets.any((TrendBucket b) => b.revenue == const Money.zero('USD')),
        isTrue,
      );
    });

    test('weeks start on a Monday', () {
      for (final TrendBucket bucket in trend(AnalyticsPeriod.days90)) {
        expect(bucket.start.weekday, DateTime.monday);
      }
    });

    test('never more than a dozen bars', () {
      expect(
        trend(AnalyticsPeriod.all).length,
        lessThanOrEqualTo(ProfitTrend.maxBuckets),
      );
    });

    test('revenue adds up to every counted sale in the window', () {
      final Money total = trend(AnalyticsPeriod.all)
          .map((TrendBucket b) => b.revenue)
          .fold(const Money.zero('USD'), (Money a, Money b) => a + b);
      final Money expected = orders
          .where((Order o) => o.status.countsAsRevenue)
          .map((Order o) => o.salePrice - (o.refund ?? const Money.zero('USD')))
          .fold(const Money.zero('USD'), (Money a, Money b) => a + b);

      expect(total, expected);
    });

    test('a bucket holding a sale with no payout has no profit bar', () {
      final Order unpaid = orders.first.copyWith(
        clearPayout: true,
        orderedAt: testNow,
      );
      final List<TrendBucket> buckets = trend(
        AnalyticsPeriod.days7,
        from: <Order>[unpaid],
      );

      expect(buckets.last.revenue, isNot(const Money.zero('USD')));
      expect(buckets.last.profit, isNull, reason: 'never a partial sum');
    });

    test('no sale in the window means no buckets at all', () {
      final Order old = orders.first.copyWith(orderedAt: DateTime(2020));

      expect(trend(AnalyticsPeriod.days7, from: <Order>[old]), isEmpty);
    });
  });
}

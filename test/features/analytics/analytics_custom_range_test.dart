import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/analytics/domain/entities/analytics_date_range.dart';
import 'package:reseller_studio/features/analytics/domain/entities/trend_bucket.dart';
import 'package:reseller_studio/features/analytics/domain/enums/analytics_period.dart';
import 'package:reseller_studio/features/analytics/domain/services/analytics_period_window.dart';
import 'package:reseller_studio/features/analytics/domain/services/profit_trend.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';

/// A Custom period covers exactly the days the seller picked — both ends
/// included — and its trend stops at the last of them, not at today.
void main() {
  final DateTime now = DateTime(2026, 10, 12, 15);
  final AnalyticsDateRange range = AnalyticsDateRange(
    from: DateTime(2026, 10, 1),
    to: DateTime(2026, 10, 9),
  );
  Order sale(String id, DateTime at) => Order(
    id: id,
    status: OrderStatus.delivered,
    marketplaceRecordId: 'ebay',
    marketplaceNameSnapshot: 'eBay',
    lines: const <OrderLine>[],
    salePrice: const Money(1000, 'USD'),
    orderedAt: at,
  );

  test('the window runs from the first day to the end of the last', () {
    expect(
      AnalyticsPeriodWindow.startOf(AnalyticsPeriod.custom, now, custom: range),
      DateTime(2026, 10, 1),
    );
    expect(
      AnalyticsPeriodWindow.endOf(AnalyticsPeriod.custom, custom: range),
      DateTime(2026, 10, 10),
    );

    final List<Order> kept = AnalyticsPeriodWindow.orders(
      <Order>[
        sale('before', DateTime(2026, 9, 30, 23)),
        sale('first', DateTime(2026, 10, 1)),
        sale('last', DateTime(2026, 10, 9, 23, 59)),
        sale('after', DateTime(2026, 10, 10)),
      ],
      DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );

    expect(kept.map((Order o) => o.id), <String>['first', 'last']);
  });

  test('no range picked yet reads as all time', () {
    expect(AnalyticsPeriodWindow.startOf(AnalyticsPeriod.custom, now), isNull);
    expect(AnalyticsPeriodWindow.endOf(AnalyticsPeriod.custom), isNull);
  });

  test('the bar width follows the span', () {
    expect(
      AnalyticsPeriodWindow.grainOf(AnalyticsPeriod.custom, custom: range),
      TrendGrain.day,
    );
    expect(
      AnalyticsPeriodWindow.grainOf(
        AnalyticsPeriod.custom,
        custom: AnalyticsDateRange(
          from: DateTime(2026, 6, 1),
          to: DateTime(2026, 7, 31),
        ),
      ),
      TrendGrain.week,
    );
  });

  test('the trend stops at the last picked day', () {
    final List<TrendBucket> buckets = ProfitTrend.build(
      orders: <Order>[sale('a', DateTime(2026, 10, 3))],
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
      now: now,
      grain: TrendGrain.day,
      currency: 'USD',
    );

    expect(buckets, hasLength(9));
    expect(buckets.last.start, DateTime(2026, 10, 9));
  });
}

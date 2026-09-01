import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/filters/date_range_filter.dart';
import 'package:reseller_studio/core/filters/presence_filter.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/entities/order_filter_criteria.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_deadline_filter.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';

/// What Orders' filter sheet asks of an order.
void main() {
  final DateTime now = DateTime(2026, 8, 31);

  Order orderWith({
    OrderStatus status = OrderStatus.toShip,
    String? marketplaceRecordId,
    Money? payout,
    String? trackingNumber,
    DateTime? shipByDate,
    DateTime? orderedAt,
    Money salePrice = const Money(4000, 'USD'),
  }) => Order(
    id: 'ord-1',
    status: status,
    lines: const <OrderLine>[],
    salePrice: salePrice,
    orderedAt: orderedAt ?? DateTime(2026, 8, 20),
    marketplaceRecordId: marketplaceRecordId,
    payout: payout,
    trackingNumber: trackingNumber,
    shipByDate: shipByDate,
  );

  group('an empty criteria', () {
    test('matches every order and counts as no filters', () {
      expect(OrderFilterCriteria.none.matches(orderWith(), now: now), isTrue);
      expect(OrderFilterCriteria.none.activeCount, 0);
    });
  });

  group('status', () {
    test('reaches the two statuses the tabs do not offer alone', () {
      const OrderFilterCriteria cancelled = OrderFilterCriteria(
        statuses: <OrderStatus>{OrderStatus.cancelled},
      );

      expect(
        cancelled.matches(orderWith(status: OrderStatus.cancelled), now: now),
        isTrue,
      );
      expect(cancelled.matches(orderWith(), now: now), isFalse);
    });
  });

  group('marketplace', () {
    test('matches the order\'s resolved marketplace id', () {
      const OrderFilterCriteria ebay = OrderFilterCriteria(
        marketplaceIds: <String>{'mkt-1'},
      );

      expect(
        ebay.matches(orderWith(marketplaceRecordId: 'mkt-1'), now: now),
        isTrue,
      );
      expect(
        ebay.matches(orderWith(marketplaceRecordId: 'mkt-2'), now: now),
        isFalse,
      );
    });
  });

  group('deadline', () {
    test('overdue is a question about the clock and the status', () {
      const OrderFilterCriteria overdue = OrderFilterCriteria(
        deadline: OrderDeadlineFilter.overdue,
      );
      final DateTime passed = DateTime(2026, 8, 20);

      expect(
        overdue.matches(orderWith(shipByDate: passed), now: now),
        isTrue,
      );
      // Already shipped: nothing is late about it any more.
      expect(
        overdue.matches(
          orderWith(status: OrderStatus.shipped, shipByDate: passed),
          now: now,
        ),
        isFalse,
      );
      // No deadline is not "on time" — it is no deadline.
      expect(overdue.matches(orderWith(), now: now), isFalse);
    });

    test('no deadline finds the orders the platform gave no date for', () {
      const OrderFilterCriteria none = OrderFilterCriteria(
        deadline: OrderDeadlineFilter.noDeadline,
      );

      expect(none.matches(orderWith(), now: now), isTrue);
      expect(
        none.matches(orderWith(shipByDate: DateTime(2026, 9, 5)), now: now),
        isFalse,
      );
    });
  });

  group('presence groups', () {
    test('awaiting payout is the absence of a reported one', () {
      const OrderFilterCriteria awaiting = OrderFilterCriteria(
        payout: PresenceFilter.absent,
      );

      expect(awaiting.matches(orderWith(), now: now), isTrue);
      expect(
        awaiting.matches(
          orderWith(payout: const Money(3600, 'USD')),
          now: now,
        ),
        isFalse,
      );
    });

    test('tracking is read off the number, not off the status', () {
      const OrderFilterCriteria tracked = OrderFilterCriteria(
        tracking: PresenceFilter.present,
      );

      expect(
        tracked.matches(
          orderWith(status: OrderStatus.shipped),
          now: now,
        ),
        isFalse,
      );
      expect(
        tracked.matches(orderWith(trackingNumber: 'AB1'), now: now),
        isTrue,
      );
    });
  });

  group('ordered range', () {
    test('narrows by when the sale happened', () {
      const OrderFilterCriteria lastWeek = OrderFilterCriteria(
        ordered: DateRangeFilter.last7Days,
      );

      expect(
        lastWeek.matches(orderWith(orderedAt: DateTime(2026, 8, 28)), now: now),
        isTrue,
      );
      expect(lastWeek.matches(orderWith(), now: now), isFalse);
    });
  });

  group('sale price window', () {
    test('bounds are inclusive and another currency is excluded', () {
      const OrderFilterCriteria over30 = OrderFilterCriteria(
        minSale: Money(3000, 'USD'),
      );

      expect(
        over30.matches(orderWith(salePrice: const Money(3000, 'USD')), now: now),
        isTrue,
      );
      expect(
        over30.matches(orderWith(salePrice: const Money(2999, 'USD')), now: now),
        isFalse,
      );
      expect(
        over30.matches(
          orderWith(salePrice: const Money(900000, 'VND')),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('activeCount', () {
    test('counts groups, not chips', () {
      const OrderFilterCriteria criteria = OrderFilterCriteria(
        statuses: <OrderStatus>{OrderStatus.toShip, OrderStatus.shipped},
        marketplaceIds: <String>{'mkt-1'},
        payout: PresenceFilter.absent,
      );

      expect(criteria.activeCount, 3);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';

/// Money a marketplace should have paid by now.
///
/// The one figure in the app that hands the seller something back rather than
/// asking them for work, so what it counts has to be exactly right: a payout
/// three days old is a platform working normally, and a parcel still on the
/// table is owed nothing at all.
void main() {
  const String usd = 'USD';

  final DateTime now = DateTime(2026, 6, 1);

  Money usdOf(int minor) => Money(minor, usd);

  Order orderOf({
    required OrderStatus status,
    DateTime? shippedAt,
    Money? payout,
  }) => Order(
    id: 'ord',
    status: status,
    marketplace: Marketplace.ebay,
    lines: <OrderLine>[
      OrderLine(
        itemId: 'itm',
        title: 'Jacket',
        quantity: 1,
        unitPrice: usdOf(10000),
      ),
    ],
    salePrice: usdOf(10000),
    orderedAt: now.subtract(const Duration(days: 40)),
    shippedAt: shippedAt,
    payout: payout,
  );

  Order shippedDaysAgo(int days) => orderOf(
    status: OrderStatus.shipped,
    shippedAt: now.subtract(Duration(days: days)),
  );

  group('PayoutReconciliation.overdue', () {
    test('chases nothing inside the normal settlement window', () {
      expect(
        PayoutReconciliation.overdue(<Order>[shippedDaysAgo(3)], now),
        isEmpty,
      );
      expect(
        PayoutReconciliation.overdue(
          <Order>[shippedDaysAgo(PayoutReconciliation.overdueAfterDays - 1)],
          now,
        ),
        isEmpty,
      );
    });

    test('chases a sale the platform has sat on', () {
      expect(
        PayoutReconciliation.overdue(<Order>[shippedDaysAgo(30)], now),
        hasLength(1),
      );
    });

    test('a parcel still on the table is owed nothing', () {
      // Never shipped, so no platform owes anything yet — counting it would
      // turn this into a complaint about the seller's own queue.
      expect(
        PayoutReconciliation.overdue(
          <Order>[orderOf(status: OrderStatus.toShip)],
          now,
        ),
        isEmpty,
      );
    });

    test('a settled sale is not outstanding', () {
      expect(
        PayoutReconciliation.overdue(<Order>[
          orderOf(
            status: OrderStatus.delivered,
            shippedAt: now.subtract(const Duration(days: 30)),
            payout: usdOf(8700),
          ),
        ], now),
        isEmpty,
      );
    });

    test('a cancelled sale is not money anybody owes', () {
      expect(
        PayoutReconciliation.overdue(<Order>[
          orderOf(
            status: OrderStatus.cancelled,
            shippedAt: now.subtract(const Duration(days: 30)),
          ),
        ], now),
        isEmpty,
      );
    });
  });

  group('PayoutReconciliation.overdueTotal', () {
    test('sums what the sales should have paid, net of the fee', () {
      // $100 on eBay at 13.25% is $86.75 expected.
      expect(
        PayoutReconciliation.overdueTotal(<Order>[shippedDaysAgo(30)], now),
        usdOf(8675),
      );
    });

    test('is null with nothing outstanding, never zero', () {
      // Hard rule 5: "nothing is late" and "you are owed nothing" are two
      // different claims, and only one of them is true here.
      expect(PayoutReconciliation.overdueTotal(const <Order>[], now), isNull);
    });
  });
}

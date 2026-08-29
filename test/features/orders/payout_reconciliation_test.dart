import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';

/// An unreported fee and a refund landing after the sale are the only
/// interesting cases here, so every row is placed against one.
void main() {
  Order order(
    String id, {
    Marketplace marketplace = Marketplace.ebay,
    OrderStatus status = OrderStatus.delivered,
    int sale = 10000,
    int? fees,
    int? shipping,
    int? refund,
    int? payout,
    DateTime? orderedAt,
  }) => Order(
    id: id,
    status: status,
    marketplace: marketplace,
    lines: <OrderLine>[
      OrderLine(
        itemId: 'itm-1',
        title: 'A jacket',
        quantity: 1,
        unitPrice: Money(sale, 'USD'),
      ),
    ],
    salePrice: Money(sale, 'USD'),
    orderedAt: orderedAt ?? DateTime(2026, 8, 1),
    fees: fees == null ? null : Money(fees, 'USD'),
    shippingCost: shipping == null ? null : Money(shipping, 'USD'),
    refund: refund == null ? null : Money(refund, 'USD'),
    payout: payout == null ? null : Money(payout, 'USD'),
  );

  group('what one order should pay out', () {
    test('a reported fee and postage come off the sale price', () {
      expect(
        PayoutReconciliation.expected(
          order('ord-1', fees: 1200, shipping: 800),
        ).minor,
        8000,
      );
      expect(
        PayoutReconciliation.isEstimated(order('ord-1', fees: 1200)),
        isFalse,
      );
    });

    test('an unreported fee falls back to the estimate, never to zero', () {
      final Order unreported = order('ord-2');

      // Zero would claim the platform worked for free, which overstates every
      // figure built on it.
      expect(PayoutReconciliation.expected(unreported).minor, lessThan(10000));
      expect(PayoutReconciliation.isEstimated(unreported), isTrue);
    });

    test('a refund comes off before the platform cut', () {
      expect(
        PayoutReconciliation.expected(
          order('ord-3', fees: 1000, refund: 2000),
        ).minor,
        7000,
      );
    });
  });

  group('what a marketplace still owes', () {
    test('orders split into settled and awaiting', () {
      final List<MarketplacePayout> rows = PayoutReconciliation.byMarketplace(
        <Order>[
          order('ord-1', fees: 1000, payout: 9000),
          order('ord-2', fees: 1000),
        ],
      );

      expect(rows, hasLength(1));
      expect(rows.single.settled.map((Order o) => o.id), <String>['ord-1']);
      expect(rows.single.awaiting.map((Order o) => o.id), <String>['ord-2']);
      expect(rows.single.settledTotal!.minor, 9000);
      expect(rows.single.awaitingTotal!.minor, 9000);
      expect(rows.single.awaitingIsEstimated, isFalse);
    });

    test('one unreported fee marks the whole awaiting figure an estimate', () {
      final List<MarketplacePayout> rows = PayoutReconciliation.byMarketplace(
        <Order>[order('ord-1', fees: 1000), order('ord-2')],
      );

      expect(rows.single.awaitingIsEstimated, isTrue);
    });

    test('an order that earned nothing is not owed', () {
      // Cancelled and refunded orders never produce a deposit, so counting
      // them would have the seller chasing money nobody owes.
      expect(
        PayoutReconciliation.byMarketplace(<Order>[
          order('ord-1', status: OrderStatus.cancelled),
          order('ord-2', status: OrderStatus.refunded),
        ]),
        isEmpty,
      );
    });

    test('the oldest unsettled order comes first', () {
      final List<MarketplacePayout> rows =
          PayoutReconciliation.byMarketplace(<Order>[
            order('ord-new', orderedAt: DateTime(2026, 8, 10)),
            order('ord-old', orderedAt: DateTime(2026, 6, 1)),
          ]);

      expect(rows.single.awaiting.first.id, 'ord-old');
    });

    test('each marketplace is its own row, busiest first', () {
      final List<MarketplacePayout> rows =
          PayoutReconciliation.byMarketplace(<Order>[
            order('ord-1', marketplace: Marketplace.etsy),
            order('ord-2', marketplace: Marketplace.ebay),
            order('ord-3', marketplace: Marketplace.ebay),
          ]);

      expect(rows.first.marketplace, Marketplace.ebay);
      expect(rows.first.awaiting, hasLength(2));
      expect(rows.last.marketplace, Marketplace.etsy);
    });
  });
}

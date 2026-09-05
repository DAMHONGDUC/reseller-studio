import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';

/// A platform's cut is measured from the payout, never estimated.
///
/// The app used to guess a fee from a published rate and label the result
/// approximate. It stopped (hard rule 3): every platform shows the seller what
/// they actually received, a rate table tops out near 95% on the largest of
/// them, and a plausible number nobody can tell from a fact is worse than a
/// dash. These pin both halves — what a recorded payout yields, and that a
/// missing one leaves the profit unknown rather than optimistic.
void main() {
  const String usd = 'USD';

  Money usdOf(int minor) => Money(minor, usd);

  Order orderOf({
    Marketplace marketplace = Marketplace.poshmark,
    Money? payout,
    Money? shippingCost,
    Money? refund,
    Money? unitCost,
  }) => Order(
    id: 'ord-1',
    status: OrderStatus.toShip,
    marketplace: marketplace,
    lines: <OrderLine>[
      OrderLine(
        itemId: 'itm-1',
        title: 'Vintage jacket',
        quantity: 1,
        unitPrice: usdOf(10000),
        unitCost: unitCost,
      ),
    ],
    salePrice: usdOf(10000),
    orderedAt: DateTime(2026, 3, 1),
    payout: payout,
    shippingCost: shippingCost,
    refund: refund,
  );

  group('Order.platformFees', () {
    test('is what the buyer paid less what arrived', () {
      final Order order = orderOf(payout: usdOf(8000));

      expect(order.platformFees, usdOf(2000));
      expect(order.needsPayout, isFalse);
    });

    test('is unknown until a payout is recorded', () {
      final Order order = orderOf();

      expect(order.platformFees, isNull);
      expect(order.needsPayout, isTrue);
    });

    test('takes the postage back out, so the shipping line carries it '
        'once', () {
      // The platform deducted a $12 label from the $80 it paid.
      final Order order = orderOf(
        payout: usdOf(6800),
        shippingCost: usdOf(1200),
      );

      expect(order.platformFees, usdOf(2000));
    });

    test('a refund is money that never reached the platform either', () {
      final Order order = orderOf(payout: usdOf(4000), refund: usdOf(4000));

      expect(order.platformFees, usdOf(2000));
    });
  });

  group('Order.profit', () {
    test('subtracts the measured cut', () {
      final ProfitBreakdown breakdown = orderOf(
        payout: usdOf(8000),
        unitCost: usdOf(3000),
      ).profit();

      // $100 sale, $30 cost, $20 the platform kept.
      expect(breakdown.netProfit, usdOf(5000));
      expect(breakdown.isComplete, isTrue);
    });

    test('is unknown when the payout is, rather than optimistic', () {
      final ProfitBreakdown breakdown = orderOf(unitCost: usdOf(3000)).profit();

      // Never the $70 a zeroed fee would have claimed, and never the $50 a
      // guessed one would have.
      expect(breakdown.fees, isNull);
      expect(breakdown.netProfit, isNull);
      expect(breakdown.margin, isNull);
      expect(breakdown.roi, isNull);
      expect(breakdown.isComplete, isFalse);
    });
  });

  group('PayoutReconciliation', () {
    test('expects nothing it cannot measure', () {
      expect(PayoutReconciliation.expected(orderOf()), isNull);
    });

    test('a recorded payout forecasts itself', () {
      final Order order = orderOf(payout: usdOf(8000));

      expect(PayoutReconciliation.expected(order), usdOf(8000));
    });

    test('the implied fee is the inverse of the forecast', () {
      final Order order = orderOf(shippingCost: usdOf(1200));

      expect(
        PayoutReconciliation.feeImpliedBy(order, usdOf(6800)),
        usdOf(2000),
      );
    });
  });
}

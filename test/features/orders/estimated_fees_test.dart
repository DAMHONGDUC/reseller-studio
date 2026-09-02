import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';

/// An unreported commission is estimated, never zeroed.
///
/// The app has no marketplace integration (hard rule 10), so `Order.fees`
/// arrives only when a seller types it — which for most orders is never.
/// Treating that null as zero claimed the platform worked for free and
/// overstated profit by the whole commission: a fifth of the sale price on
/// Poshmark. These pin that it does not, and that an estimate says it is one.
void main() {
  const String usd = 'USD';

  Money usdOf(int minor) => Money(minor, usd);

  Order orderOf({
    Marketplace marketplace = Marketplace.poshmark,
    Money? fees,
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
    fees: fees,
  );

  group('Order.effectiveFees', () {
    test('estimates from the platform rate when nobody reported one', () {
      final Order order = orderOf();

      // Poshmark takes 20%, so $100 sold is $20 gone.
      expect(order.effectiveFees(const <String, double>{}), usdOf(2000));
      expect(order.feesAreEstimated, isTrue);
    });

    test('a reported fee always wins over the estimate', () {
      final Order order = orderOf(fees: usdOf(1750));

      expect(order.effectiveFees(const <String, double>{}), usdOf(1750));
      expect(order.feesAreEstimated, isFalse);
    });

    test("the workspace's own corrected rate beats the published one", () {
      final Order order = orderOf();

      expect(
        order.effectiveFees(const <String, double>{'poshmark': 0.15}),
        usdOf(1500),
      );
    });
  });

  group('Order.profit', () {
    test('does not report the commission as profit', () {
      final ProfitBreakdown breakdown = orderOf(
        unitCost: usdOf(3000),
      ).profit();

      // $100 sale, $30 cost, $20 commission — never the $70 a zeroed fee
      // would have claimed.
      expect(breakdown.netProfit, usdOf(5000));
      expect(breakdown.feesAreEstimated, isTrue);
    });

    test('a marketplace that charges nothing is not an estimate worth a '
        'label', () {
      final ProfitBreakdown breakdown = orderOf(
        marketplace: Marketplace.other,
        unitCost: usdOf(3000),
      ).profit();

      expect(breakdown.fees, usdOf(0));
      expect(breakdown.netProfit, usdOf(7000));
    });
  });

  group('PayoutReconciliation', () {
    test('forecasts the payout from the same fee the profit statement '
        'uses', () {
      final Order order = orderOf();

      expect(PayoutReconciliation.expected(order), usdOf(8000));
      expect(PayoutReconciliation.isEstimated(order), isTrue);
    });
  });
}

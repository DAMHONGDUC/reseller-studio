import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/reports/domain/services/bookkeeping_gaps.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';

/// What the tax export leans on.
///
/// A summary is only as exact as the rows under it, so the thing that decides
/// whether a figure is worth handing to an accountant is whether anything
/// under it is still a guess. These pin what counts as a guess and — just as
/// important — what does not, because a screen that sends a seller to fix a
/// record that is already correct is one they stop opening.
void main() {
  const String usd = 'USD';

  final DateTime now = DateTime(2026, 6, 1);

  Money usdOf(int minor) => Money(minor, usd);

  Order orderOf({
    required String id,
    OrderStatus status = OrderStatus.delivered,
    Money? fees,
    Money? unitCost,
    Money? payout,
    DateTime? shippedAt,
  }) => Order(
    id: id,
    status: status,
    marketplace: Marketplace.ebay,
    lines: <OrderLine>[
      OrderLine(
        itemId: 'itm-$id',
        title: 'Jacket',
        quantity: 1,
        unitPrice: usdOf(10000),
        unitCost: unitCost,
      ),
    ],
    salePrice: usdOf(10000),
    orderedAt: now.subtract(const Duration(days: 40)),
    fees: fees,
    payout: payout,
    shippedAt: shippedAt,
  );

  Purchase purchaseOf({required String id, String? receiptUrl}) => Purchase(
    id: id,
    purchaseDate: now.subtract(const Duration(days: 10)),
    createdAt: now,
    receiptUrl: receiptUrl,
  );

  BookkeepingGaps gapsFor(List<Order> orders, {List<Purchase>? purchases}) =>
      BookkeepingGaps.from(
        orders: orders,
        purchases: purchases ?? const <Purchase>[],
        now: now,
      );

  test('a fee nobody entered is a gap; one that was entered is not', () {
    final BookkeepingGaps gaps = gapsFor(<Order>[
      orderOf(id: 'a', unitCost: usdOf(3000), payout: usdOf(8000)),
      orderOf(
        id: 'b',
        fees: usdOf(1325),
        unitCost: usdOf(3000),
        payout: usdOf(8000),
      ),
    ]);

    expect(gaps.estimatedFees.map((Order o) => o.id), <String>['a']);
  });

  test('a missing item cost is its own gap, worse than an estimate', () {
    final BookkeepingGaps gaps = gapsFor(<Order>[
      orderOf(id: 'a', fees: usdOf(1325), payout: usdOf(8000)),
    ]);

    // Nothing to estimate from: the profit is not approximate, it is
    // unknowable, and the app renders a dash (hard rule 5).
    expect(gaps.unknownCost.map((Order o) => o.id), <String>['a']);
    expect(gaps.estimatedFees, isEmpty);
  });

  test('a cancelled sale is never work to do', () {
    // It has no fee worth chasing and no cost worth entering. Listing it
    // would send the seller to fix a record that is already correct.
    final BookkeepingGaps gaps = gapsFor(<Order>[
      orderOf(id: 'a', status: OrderStatus.cancelled),
      orderOf(id: 'b', status: OrderStatus.refunded),
    ]);

    expect(gaps.isClear, isTrue);
  });

  test('a purchase with a receipt is filed; one without is not', () {
    final BookkeepingGaps gaps = gapsFor(
      const <Order>[],
      purchases: <Purchase>[
        purchaseOf(id: 'p1'),
        purchaseOf(id: 'p2', receiptUrl: 'https://example.test/r.pdf'),
      ],
    );

    expect(
      gaps.receiptlessPurchases.map((Purchase p) => p.id),
      <String>['p1'],
    );
  });

  test('one sale missing two figures is two pieces of work', () {
    // Rolling them into one would understate what is left to do, and the
    // count is the whole point of the screen's opening line.
    final BookkeepingGaps gaps = gapsFor(<Order>[
      orderOf(id: 'a', payout: usdOf(8000)),
    ]);

    expect(gaps.total, 2);
    expect(gaps.isClear, isFalse);
  });

  test('nothing missing reads as clear', () {
    final BookkeepingGaps gaps = gapsFor(<Order>[
      orderOf(
        id: 'a',
        fees: usdOf(1325),
        unitCost: usdOf(3000),
        payout: usdOf(8000),
      ),
    ]);

    expect(gaps.total, 0);
    expect(gaps.isClear, isTrue);
  });

  group('narrowed to one filing period', () {
    test('a sale from another year is not this return\'s problem', () {
      final Order lastYear = Order(
        id: 'old',
        status: OrderStatus.delivered,
        marketplace: Marketplace.ebay,
        lines: <OrderLine>[
          OrderLine(
            itemId: 'itm-old',
            title: 'Jacket',
            quantity: 1,
            unitPrice: usdOf(10000),
          ),
        ],
        salePrice: usdOf(10000),
        orderedAt: DateTime(2024, 3, 1),
      );

      final BookkeepingGaps whole = BookkeepingGaps.from(
        orders: <Order>[lastYear],
        purchases: const <Purchase>[],
        now: now,
      );
      final BookkeepingGaps thisYear = BookkeepingGaps.from(
        orders: <Order>[lastYear],
        purchases: const <Purchase>[],
        now: now,
        from: DateTime(2026),
        toExclusive: DateTime(2027),
      );

      expect(whole.isClear, isFalse);
      expect(thisYear.isClear, isTrue);
      expect(thisYear.checkedOrders, 0);
    });

    test('the checked count is what gives the estimate count meaning', () {
      // "0 estimated" says nothing without "out of 128".
      final BookkeepingGaps gaps = gapsFor(<Order>[
        orderOf(
          id: 'a',
          fees: usdOf(1325),
          unitCost: usdOf(3000),
          payout: usdOf(8000),
        ),
        orderOf(
          id: 'b',
          fees: usdOf(1325),
          unitCost: usdOf(3000),
          payout: usdOf(8000),
        ),
      ]);

      expect(gaps.checkedOrders, 2);
      expect(gaps.estimatedFees, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/analytics/domain/services/dropship_performance.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_fulfilment.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/entities/supplier_order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/enums/supplier_order_status.dart';

/// The dropship breakdown: who ships what, which products earn, and how fast
/// each supplier dispatches.
void main() {
  Item item(String id, ItemFulfilment fulfilment) => Item(
    id: id,
    title: id,
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: DateTime(2026, 10, 1),
    fulfilment: fulfilment,
  );
  Order sale(String id, String itemId, int price, int? cost) => Order(
    id: id,
    status: OrderStatus.delivered,
    marketplaceRecordId: 'ebay',
    marketplaceNameSnapshot: 'eBay',
    lines: <OrderLine>[
      OrderLine(
        itemId: itemId,
        title: itemId,
        quantity: 1,
        unitPrice: Money(price, 'USD'),
        unitCost: cost == null ? null : Money(cost, 'USD'),
      ),
    ],
    salePrice: Money(price, 'USD'),
    orderedAt: DateTime(2026, 10, 2),
  );
  final List<Item> items = <Item>[
    item('shelf', ItemFulfilment.stocked),
    item('ds-a', ItemFulfilment.dropship),
    item('ds-b', ItemFulfilment.dropship),
  ];
  final List<Order> orders = <Order>[
    sale('o1', 'shelf', 3000, 1000),
    sale('o2', 'ds-a', 4500, 1500),
    sale('o3', 'ds-b', 4000, null),
  ];

  test('splits the business by who ships it', () {
    final ({FulfilmentFigures stocked, FulfilmentFigures dropship}) split =
        DropshipPerformance.split(
          orders: orders,
          items: <String, Item>{for (final Item i in items) i.id: i},
        );

    expect(split.stocked.profit, const Money(2000, 'USD'));
    expect(split.dropship.revenue, const Money(8500, 'USD'));
    // One dropship line has no cost yet, so the side's profit is unknown.
    expect(split.dropship.profit, isNull);
  });

  test('ranks products with a known profit first', () {
    final List<DropshipProductPerformance> ranked =
        DropshipPerformance.products(orders: orders, items: items);

    expect(ranked.map((DropshipProductPerformance r) => r.itemId), <String>[
      'ds-a',
      'ds-b',
    ]);
    expect(ranked.first.profit, const Money(3000, 'USD'));
  });

  test('averages each supplier from placed to shipped', () {
    SupplierOrder shipped(String id, int days) => SupplierOrder(
      id: id,
      sourceId: 'cj',
      status: SupplierOrderStatus.shipped,
      createdAt: DateTime(2026, 10, 1),
      placedAt: DateTime(2026, 10, 1),
      shippedAt: DateTime(2026, 10, 1 + days),
    );

    final List<SupplierShipTime> times = DropshipPerformance.shipTimes(
      <SupplierOrder>[shipped('a', 2), shipped('b', 4)],
    );

    expect(times.single.averageDays, 3);
    expect(times.single.shipments, 2);
  });
}

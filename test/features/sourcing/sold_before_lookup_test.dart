import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/money/money.dart';
import 'package:seller_os/features/inventory/domain/entities/item.dart';
import 'package:seller_os/features/inventory/domain/enums/item_status.dart';
import 'package:seller_os/features/marketplaces/domain/enums/marketplace.dart';
import 'package:seller_os/features/orders/domain/entities/order.dart';
import 'package:seller_os/features/orders/domain/enums/order_status.dart';
import 'package:seller_os/features/sourcing/domain/services/sold_before_lookup.dart';

/// The answer comes from the seller's own records, so the interesting cases
/// are a code matching nothing sold and one matching several sales.
void main() {
  Item item(String id, {String? barcode, String? sku}) => Item(
    id: id,
    title: 'A jacket',
    quantity: 1,
    status: ItemStatus.sold,
    createdAt: DateTime(2026),
    barcode: barcode,
    sku: sku,
  );

  Order order(
    String id,
    String itemId,
    int minor,
    DateTime when, {
    OrderStatus status = OrderStatus.delivered,
  }) => Order(
    id: id,
    status: status,
    marketplace: Marketplace.ebay,
    lines: <OrderLine>[
      OrderLine(
        itemId: itemId,
        title: 'A jacket',
        quantity: 1,
        unitPrice: Money(minor, 'USD'),
      ),
    ],
    salePrice: Money(minor, 'USD'),
    orderedAt: when,
  );

  test('a barcode finds the most recent sale of that item', () {
    final SoldBefore? found = SoldBeforeLookup.find(
      code: '5012345678900',
      items: <Item>[item('itm-1', barcode: '5012345678900')],
      orders: <Order>[
        order('ord-old', 'itm-1', 2200, DateTime(2026, 3, 1)),
        order('ord-new', 'itm-1', 2800, DateTime(2026, 7, 1)),
      ],
    );

    expect(found!.salePrice.minor, 2800);
    expect(found.soldAt, DateTime(2026, 7, 1));
    expect(found.timesSold, 2);
  });

  test('a SKU works too, the way the scanner screen matches', () {
    final SoldBefore? found = SoldBeforeLookup.find(
      code: 'JKT-001',
      items: <Item>[item('itm-1', sku: 'JKT-001')],
      orders: <Order>[order('ord-1', 'itm-1', 2200, DateTime(2026, 3, 1))],
    );

    expect(found, isNotNull);
    expect(found!.timesSold, 1);
  });

  test('an item that never sold has no history', () {
    expect(
      SoldBeforeLookup.find(
        code: '5012345678900',
        items: <Item>[item('itm-1', barcode: '5012345678900')],
        orders: const <Order>[],
      ),
      isNull,
    );
  });

  test('a cancelled order is not a sale', () {
    // It never earned anything, so quoting its price back would suggest a
    // going rate nobody ever paid.
    expect(
      SoldBeforeLookup.find(
        code: '5012345678900',
        items: <Item>[item('itm-1', barcode: '5012345678900')],
        orders: <Order>[
          order(
            'ord-1',
            'itm-1',
            2200,
            DateTime(2026, 3, 1),
            status: OrderStatus.cancelled,
          ),
        ],
      ),
      isNull,
    );
  });

  test('an unknown or blank code answers nothing', () {
    final List<Item> items = <Item>[item('itm-1', barcode: '111')];

    expect(
      SoldBeforeLookup.find(code: '999', items: items, orders: const <Order>[]),
      isNull,
    );
    expect(
      SoldBeforeLookup.find(code: '  ', items: items, orders: const <Order>[]),
      isNull,
    );
  });
}

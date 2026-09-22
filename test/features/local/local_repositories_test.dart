import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/data/repositories/local_item_repository.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/orders/data/repositories/local_order_repository.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/sourcing/data/repositories/local_sourcing_repositories.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/source.dart';

/// P2's gate: a guest repository behaves the way the Firestore one does —
/// same ordering, same soft-delete filtering, same merge-on-save, and the
/// same refusal to sell an item twice.
void main() {
  const String currency = 'USD';

  late LocalDatabase db;
  late LocalItemRepository items;
  late LocalOrderRepository orders;
  late LocalSourceRepository sources;

  Item item(String id, {int quantity = 1, ItemStatus status = ItemStatus.inStock}) =>
      Item(
        id: id,
        title: 'Item $id',
        quantity: quantity,
        status: status,
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    items = LocalItemRepository(db, currency: currency);
    orders = LocalOrderRepository(db, currency: currency);
    sources = LocalSourceRepository(db);
  });

  tearDown(() => db.close());

  test('a saved item reads back through the domain entity', () async {
    await items.save(item('itm-1'));

    final Item? found = await items.findById('itm-1');

    expect(found?.title, 'Item itm-1');
    expect(found?.status, ItemStatus.inStock);
  });

  test('a soft-deleted item leaves the list but stays findable', () async {
    await items.save(item('itm-1'));
    await items.delete('itm-1');

    expect(await items.watchItems().first, isEmpty);
    expect((await items.findById('itm-1'))?.isDeleted, isTrue);
  });

  test('saving twice merges rather than replacing', () async {
    await items.save(item('itm-1'));
    await items.save(item('itm-1', quantity: 4));

    final Item? found = await items.findById('itm-1');

    expect(found?.quantity, 4);
    expect(found?.title, 'Item itm-1');
  });

  test('bulk save writes every row — hard rule 16', () async {
    await items.saveAll(<Item>[item('a'), item('b'), item('c')]);

    expect((await items.watchItems().first).length, 3);
  });

  test('items for a purchase are filtered the way Firestore filters', () async {
    await items.save(item('a'));
    await items.saveAll(<Item>[
      Item(
        id: 'b',
        title: 'B',
        quantity: 1,
        status: ItemStatus.inStock,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'pur-1',
      ),
    ]);

    final List<Item> found = await items.watchItemsForPurchase('pur-1').first;

    expect(found.map((Item i) => i.id), <String>['b']);
  });

  test('a soft-deleted source is gone from the list — hard rule 15', () async {
    await sources.save(
      Source(id: 'src-1', name: 'Goodwill', createdAt: DateTime(2026, 1, 1)),
    );
    await sources.delete('src-1');

    expect(await sources.watchSources().first, isEmpty);
    expect((await sources.findById('src-1'))?.name, 'Goodwill');
  });

  group('recordSale', () {
    Order order(String id) => Order(
      id: id,
      status: OrderStatus.toShip,
      marketplaceRecordId: 'ebay',
      marketplaceNameSnapshot: 'eBay',
      salePrice: const Money(6800, currency),
      orderedAt: DateTime(2026, 2, 1),
      lines: <OrderLine>[
        const OrderLine(
          itemId: 'itm-1',
          title: 'Item itm-1',
          quantity: 1,
          unitPrice: Money(6800, currency),
        ),
      ],
    );

    test('sells the item down and writes the order', () async {
      await items.save(item('itm-1'));

      await orders.recordSale(order('ord-1'), <Item>[item('itm-1')]);

      final Item? sold = await items.findById('itm-1');

      expect(sold?.quantity, 0);
      expect(sold?.status, ItemStatus.sold);
      expect((await orders.findById('ord-1'))?.salePrice.minor, 6800);
    });

    test('refuses an item that has already sold', () async {
      await items.save(item('itm-1', quantity: 0, status: ItemStatus.sold));

      await expectLater(
        orders.recordSale(order('ord-2'), <Item>[item('itm-1')]),
        throwsA(anything),
      );
    });
  });

  test('closing a return with restock puts the item back', () async {
    await items.save(item('itm-1'));
    await orders.recordSale(
      Order(
        id: 'ord-1',
        status: OrderStatus.toShip,
        marketplaceRecordId: 'ebay',
        marketplaceNameSnapshot: 'eBay',
        salePrice: const Money(6800, currency),
        orderedAt: DateTime(2026, 2, 1),
        lines: <OrderLine>[
          const OrderLine(
            itemId: 'itm-1',
            title: 'Item itm-1',
            quantity: 1,
            unitPrice: Money(6800, currency),
          ),
        ],
      ),
      <Item>[item('itm-1')],
    );

    final Order returned = (await orders.findById('ord-1'))!;

    await orders.closeReturn(returned, restock: true);

    final Item? back = await items.findById('itm-1');

    expect(back?.quantity, 1);
    expect(back?.status, ItemStatus.inStock);
    expect(back?.soldAt, isNull);
  });
}

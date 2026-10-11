import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/expenses/domain/entities/expense.dart';
import 'package:reseller_studio/features/expenses/providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_fulfilment.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/entities/order_filter_criteria.dart';
import 'package:reseller_studio/features/orders/domain/entities/supplier_order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_supplier_stage.dart';
import 'package:reseller_studio/features/orders/domain/enums/supplier_order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/supplier_orders.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/supplier_order_controller.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:reseller_studio/features/receipts/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/supplier_product.dart';

import '../../support/pump_app.dart';

/// Orders placed with a dropship supplier: what is still to order, how long
/// it has waited, and the sold line's cost following the supplier order.
void main() {
  final DateTime sold = DateTime(2026, 10, 1);
  Item dropship(String id) => Item(
    id: id,
    title: 'Jacket',
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: sold,
    fulfilment: ItemFulfilment.dropship,
  );
  Order order(String id, String itemId) => Order(
    id: id,
    status: OrderStatus.toShip,
    marketplaceRecordId: 'ebay',
    marketplaceNameSnapshot: 'eBay',
    lines: <OrderLine>[
      OrderLine(
        itemId: itemId,
        title: 'Jacket',
        quantity: 1,
        unitPrice: const Money(4500, 'USD'),
      ),
    ],
    salePrice: const Money(4500, 'USD'),
    orderedAt: sold,
  );
  SupplierOrder placed({
    String orderId = 'o1',
    SupplierOrderStatus status = SupplierOrderStatus.placed,
    Money? refund,
  }) => SupplierOrder(
    id: 'so-1',
    sourceId: 'cj',
    status: status,
    createdAt: sold,
    orderId: orderId,
    itemId: 'd1',
    productCost: const Money(1200, 'USD'),
    shippingCost: const Money(300, 'USD'),
    supplierRefund: refund,
    placedAt: sold,
  );

  group('SupplierOrders', () {
    test('a sold dropship line with no supplier order is to place', () {
      final List<SupplierOrderToPlace> pending = SupplierOrders.toPlace(
        orders: <Order>[order('o1', 'd1'), order('o2', 'd1')],
        items: <String, Item>{'d1': dropship('d1')},
        supplierOrders: <SupplierOrder>[placed()],
      );

      expect(pending.single.order.id, 'o2');
    });

    test('a cancelled supplier order puts the line back to place', () {
      expect(
        SupplierOrders.toPlace(
          orders: <Order>[order('o1', 'd1')],
          items: <String, Item>{'d1': dropship('d1')},
          supplierOrders: <SupplierOrder>[
            placed(status: SupplierOrderStatus.cancelled),
          ],
        ),
        hasLength(1),
      );
    });

    test('days waiting, late and arrival read off the placed date', () {
      final DateTime now = DateTime(2026, 10, 10);

      expect(SupplierOrders.daysAwaitingShipment(placed(), now), 9);
      expect(SupplierOrders.isLate(placed(), now, 7), isTrue);
      expect(
        SupplierOrders.estimatedArrival(placed(), 12),
        DateTime(2026, 10, 13),
      );
      expect(
        SupplierOrders.daysAwaitingShipment(
          placed(status: SupplierOrderStatus.shipped),
          now,
        ),
        isNull,
      );
    });

    test('stages: to order outranks late, late outranks waiting', () {
      final DateTime now = DateTime(2026, 10, 10);
      final Map<String, OrderSupplierStage> stages =
          SupplierOrders.stagesByOrder(
            orders: <Order>[order('o1', 'd1'), order('o2', 'd1')],
            items: <String, Item>{'d1': dropship('d1')},
            supplierOrders: <SupplierOrder>[placed()],
            now: now,
            lateAfterDays: 7,
          );

      expect(stages['o1'], OrderSupplierStage.late);
      expect(stages['o2'], OrderSupplierStage.toOrder);
    });

    test('the supplier filter keeps only orders at a picked stage', () {
      final OrderFilterCriteria criteria = OrderFilterCriteria.none
          .withSupplierStageToggled(OrderSupplierStage.toOrder);

      expect(
        criteria.matches(
          order('o2', 'd1'),
          now: sold,
          supplierStage: OrderSupplierStage.toOrder,
        ),
        isTrue,
      );
      expect(criteria.matches(order('o3', 'x'), now: sold), isFalse);
    });

    test('the net cost subtracts a supplier refund', () {
      expect(SupplierOrders.netCost(placed()), const Money(1500, 'USD'));
      expect(
        SupplierOrders.netCost(placed(refund: const Money(500, 'USD'))),
        const Money(1000, 'USD'),
      );
      expect(
        SupplierOrders.netCost(placed(status: SupplierOrderStatus.cancelled)),
        isNull,
      );
    });
  });

  group('a dropship sale', () {
    late ProviderContainer container;

    setUp(() async {
      container = mockContainer();
      container
        ..listen(itemsProvider, (_, _) {}, fireImmediately: true)
        ..listen(ordersProvider, (_, _) {}, fireImmediately: true)
        ..listen(supplierOrdersProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await container.read(itemRepositoryProvider).save(dropship('d1'));
      await Future<void>.delayed(Duration.zero);
    });

    Future<Order> sell() async {
      final String id = await container
          .read(recordSaleControllerProvider.notifier)
          .record(
            <Item>[dropship('d1')],
            salePrice: const Money(4500, 'USD'),
            marketplaceId: 'ebay',
            marketplaceName: 'eBay',
            soldAt: sold,
          );
      await Future<void>.delayed(Duration.zero);

      return container
          .read(ordersProvider)
          .value!
          .firstWhere((Order o) => o.id == id);
    }

    test(
      'a sample is a supplier order and an expense, not a sale cost',
      () async {
        container.listen(expensesProvider, (_, _) {}, fireImmediately: true);
        await Future<void>.delayed(Duration.zero);

        await container
            .read(supplierOrderControllerProvider.notifier)
            .orderSample(
              product: SupplierProduct(
                id: 'sp-1',
                sourceId: 'cj',
                title: 'Jacket',
                createdAt: sold,
              ),
              cost: const Money(900, 'USD'),
              supplierName: 'CJ',
            );
        await Future<void>.delayed(Duration.zero);

        final SupplierOrder sample = container
            .read(supplierOrdersProvider)
            .value!
            .single;
        final Expense expense = container
            .read(expensesProvider)
            .value!
            .firstWhere((Expense e) => e.supplierOrderId == sample.id);

        expect(sample.isSample, isTrue);
        expect(expense.amount, const Money(900, 'USD'));
        expect(container.read(supplierOrdersToPlaceProvider), isEmpty);
      },
    );

    test(
      'an invoice on a supplier order is listed with the receipts',
      () async {
        final Order sale = await sell();

        await container
            .read(supplierOrderControllerProvider.notifier)
            .place(
              order: sale,
              line: sale.lines.single,
              sourceId: 'cj',
              productCost: const Money(1200, 'USD'),
            );
        await Future<void>.delayed(Duration.zero);

        final SupplierOrder so = container
            .read(supplierOrdersForOrderProvider(sale.id))
            .single;

        await container
            .read(supplierOrderRepositoryProvider)
            .save(so.copyWith(invoiceUrl: 'file://invoice.jpg'));
        await Future<void>.delayed(Duration.zero);

        expect(
          container
              .read(receiptsProvider)
              .where((ReceiptEntry r) => r.kind == ReceiptKind.supplierOrder)
              .single
              .recordId,
          sale.id,
        );
      },
    );

    test('stays for sale, and waits to be ordered', () async {
      await sell();

      final Item item = container
          .read(itemsProvider)
          .value!
          .firstWhere((Item i) => i.id == 'd1');

      expect(item.status, ItemStatus.inStock);
      expect(item.quantity, 1);
      expect(container.read(supplierOrdersToPlaceProvider), hasLength(1));
    });

    test(
      'placing and refunding re-costs the line; tracking ships it',
      () async {
        final Order sale = await sell();
        final SupplierOrderController controller = container.read(
          supplierOrderControllerProvider.notifier,
        );

        await controller.place(
          order: sale,
          line: sale.lines.single,
          sourceId: 'cj',
          productCost: const Money(1200, 'USD'),
          shippingCost: const Money(300, 'USD'),
        );
        await Future<void>.delayed(Duration.zero);

        Order reread() => container
            .read(ordersProvider)
            .value!
            .firstWhere((Order o) => o.id == sale.id);
        final SupplierOrder so = container
            .read(supplierOrdersForOrderProvider(sale.id))
            .single;

        expect(reread().lines.single.unitCost, const Money(1500, 'USD'));
        expect(container.read(supplierOrdersToPlaceProvider), isEmpty);

        await controller.recordRefund(so, reread(), const Money(500, 'USD'));
        await Future<void>.delayed(Duration.zero);

        expect(reread().lines.single.unitCost, const Money(1000, 'USD'));

        await controller.addTracking(
          container.read(supplierOrdersForOrderProvider(sale.id)).single,
          reread(),
          trackingNumber: 'YT123',
        );
        await Future<void>.delayed(Duration.zero);

        expect(reread().status, OrderStatus.shipped);
        expect(reread().trackingNumber, 'YT123');
      },
    );
  });
}

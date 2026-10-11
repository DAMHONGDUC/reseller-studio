import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/supplier_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../dtos/order_dto.dart';
import '../dtos/supplier_order_dto.dart';

/// Supplier orders, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalSupplierOrderRepository implements SupplierOrderRepository {
  LocalSupplierOrderRepository(this._db, {required String currency})
    : _collection = LocalCollection<SupplierOrder>(
        table: LocalTable(_db, _db.localSupplierOrders),
        fromMap: (String id, Map<String, Object?> data) =>
            SupplierOrderDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (SupplierOrder order) => SupplierOrderDto.toMap(
          order,
          currency: currency,
          createdBy: GuestConstant.uid,
        ),
        idOf: (SupplierOrder order) => order.id,
        createdAtOf: (SupplierOrder order) => order.createdAt,
        logTag: LogTagConstant.dropship,
        label: 'supplier order',
      ),
      _orders = LocalCollection<Order>(
        table: LocalTable(_db, _db.localOrders),
        fromMap: (String id, Map<String, Object?> data) =>
            OrderDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Order order) =>
            OrderDto.toMap(order, createdBy: GuestConstant.uid),
        idOf: (Order order) => order.id,
        createdAtOf: (Order order) => order.orderedAt,
        logTag: LogTagConstant.order,
        label: 'order',
      );

  final LocalDatabase _db;
  final LocalCollection<SupplierOrder> _collection;
  final LocalCollection<Order> _orders;

  @override
  Stream<List<SupplierOrder>> watchSupplierOrders() => _collection.watchAll();

  /// One transaction for both tables — the local half of the Firestore batch.
  @override
  Future<void> save(SupplierOrder supplierOrder, {Order? order}) =>
      _db.transaction(() async {
        await _collection.save(supplierOrder);
        if (order != null) await _orders.save(order);
      });
}

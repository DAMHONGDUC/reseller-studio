import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/supplier_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../dtos/order_dto.dart';
import '../dtos/supplier_order_dto.dart';

/// Supplier orders, in Firestore.
class FirestoreSupplierOrderRepository implements SupplierOrderRepository {
  const FirestoreSupplierOrderRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<SupplierOrder>> watchSupplierOrders() =>
      FirestoreStream.collection(
        _context.collections.supplierOrders.query.orderBy('createdAt'),
        (DocumentSnapshot<Map<String, Object?>> doc) =>
            SupplierOrderDto.toEntity(doc, fallbackCurrency: _context.currency),
        operation: 'load supplier orders',
      );

  @override
  Future<void> save(SupplierOrder supplierOrder, {Order? order}) =>
      FailureMapper.guard('save supplier order', () async {
        final WriteBatch batch = _context.collections.supplierOrders.firestore
            .batch();

        batch.set(
          _context.collections.supplierOrders.doc(supplierOrder.id),
          SupplierOrderDto.toMap(
            supplierOrder,
            currency: _context.currency,
            createdBy: _context.uid,
          ),
          SetOptions(merge: true),
        );
        if (order != null) {
          batch.set(
            _context.collections.orders.doc(order.id),
            OrderDto.toMap(order, createdBy: _context.uid),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        SdLogger.info(
          LogTagConstant.dropship,
          'Supplier order saved',
          <String, Object>{
            'supplierOrderId': supplierOrder.id,
            'status': supplierOrder.status.name,
            'orderId': supplierOrder.orderId ?? '',
            'withOrder': order != null,
          },
        );
      });
}

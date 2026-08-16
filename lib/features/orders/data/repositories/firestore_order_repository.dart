import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../dtos/order_dto.dart';

/// Orders, in Firestore.
///
/// The Orders screen's five tabs are a fold over this one stream rather than
/// five queries — five live listeners for one screen is five times the cost
/// and five chances for the counts to disagree with the list.
class FirestoreOrderRepository implements OrderRepository {
  const FirestoreOrderRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Order>> watchOrders() => FirestoreStream.collection(
    _context.collections.orders.orderBy('orderedAt', descending: true),
    _toEntity,
    operation: 'load orders',
  );

  @override
  Stream<Order?> watchOrder(String id) => FirestoreStream.document(
    _context.collections.orders.doc(id),
    _toEntity,
    operation: 'load order',
  );

  @override
  Future<Order?> findById(String id) =>
      FailureMapper.guard('find order', () async {
        final DocumentSnapshot<Map<String, Object?>> doc = await _context
            .collections
            .orders
            .doc(id)
            .get();

        return doc.exists ? _toEntity(doc) : null;
      });

  @override
  Future<void> save(Order order) => FailureMapper.guard('save order', () async {
    await _context.collections.orders
        .doc(order.id)
        .set(
          OrderDto.toMap(order, createdBy: _context.uid),
          SetOptions(merge: true),
        );

    AppLogger.info('Order saved', <String, Object>{
      'orderId': order.id,
      'status': order.status.name,
      'lines': order.lines.length,
    });
  });

  Order _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      OrderDto.toEntity(doc, fallbackCurrency: _context.currency);
}

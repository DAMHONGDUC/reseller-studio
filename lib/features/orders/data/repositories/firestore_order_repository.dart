import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../../inventory/domain/entities/item.dart';
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
    _context.collections.orders.query.orderBy('orderedAt', descending: true),
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

    SdLogger.info(LogTagConstant.order, 'Order saved', <String, Object>{
      'orderId': order.id,
      'status': order.status.name,
      'lines': order.lines.length,
    });
  });

  @override
  Future<void> recordSale(Order order, List<Item> items) => FailureMapper.guard(
    'record sale',
    () async {
      final DocumentReference<Map<String, Object?>> orderRef = _context
          .collections
          .orders
          .doc(order.id);
      final Map<String, DocumentReference<Map<String, Object?>>> itemRefs =
          <String, DocumentReference<Map<String, Object?>>>{
            for (final Item item in items)
              item.id: _context.collections.items.doc(item.id),
          };

      // What each line was allocated, so an item's asking price is seeded
      // from its own share of a bundle rather than from the whole payment.
      final Map<String, int> linePrice = <String, int>{
        for (final OrderLine line in order.lines)
          line.itemId: line.unitPrice.minor,
      };

      await orderRef.firestore.runTransaction((Transaction transaction) async {
        final Map<String, Map<String, Object?>> read =
            <String, Map<String, Object?>>{};

        // **Every read before any write.** Firestore requires it, and it is
        // also the behaviour a bundle needs: a third item that has already
        // sold must leave the first two untouched.
        for (final Item item in items) {
          final DocumentSnapshot<Map<String, Object?>> doc = await transaction
              .get(itemRefs[item.id]!);
          final Map<String, Object?> data =
              doc.data() ?? const <String, Object?>{};
          final int quantity = data['quantity'] is int
              ? data['quantity']! as int
              : item.quantity;
          final String status = data['status'] is String
              ? data['status']! as String
              : item.status.name;

          if (!doc.exists ||
              quantity <= 0 ||
              status == 'sold' ||
              status == 'archived') {
            throw StateError('Item ${item.id} is no longer sellable');
          }

          read[item.id] = data;
        }

        transaction.set(
          orderRef,
          OrderDto.toMap(order, createdBy: _context.uid),
          SetOptions(merge: true),
        );

        for (final Item item in items) {
          final Map<String, Object?> data = read[item.id]!;
          final int quantity = data['quantity'] is int
              ? data['quantity']! as int
              : item.quantity;
          final int left = quantity - 1;

          transaction.update(itemRefs[item.id]!, <String, Object?>{
            'quantity': left,
            'status': left == 0 ? 'sold' : 'inStock',
            if (left == 0) 'soldAt': Timestamp.fromDate(order.orderedAt),
            if (data['askingPriceMinor'] == null)
              'askingPriceMinor': linePrice[item.id] ?? order.salePrice.minor,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      SdLogger.info(LogTagConstant.order, 'Sale committed', <String, Object>{
        'orderId': order.id,
        'items': items.length,
      });
    },
  );

  @override
  Future<void> closeReturn(
    Order order, {
    required bool restock,
  }) => FailureMapper.guard('close return', () async {
    final DocumentReference<Map<String, Object?>> orderRef = _context
        .collections
        .orders
        .doc(order.id);

    await orderRef.firestore.runTransaction((Transaction transaction) async {
      final Map<String, int> quantities = <String, int>{};
      for (final OrderLine line in order.lines) {
        quantities.update(
          line.itemId,
          (int value) => value + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }

      final Map<DocumentReference<Map<String, Object?>>, int> current =
          <DocumentReference<Map<String, Object?>>, int>{};
      if (restock) {
        for (final MapEntry<String, int> entry in quantities.entries) {
          final DocumentReference<Map<String, Object?>> itemRef = _context
              .collections
              .items
              .doc(entry.key);
          final DocumentSnapshot<Map<String, Object?>> itemDoc =
              await transaction.get(itemRef);
          if (!itemDoc.exists) continue;
          final Object? raw = itemDoc.data()?['quantity'];
          current[itemRef] = raw is int ? raw : 0;
        }
      }

      transaction.set(
        orderRef,
        OrderDto.toMap(order, createdBy: _context.uid),
        SetOptions(merge: true),
      );
      for (final MapEntry<DocumentReference<Map<String, Object?>>, int> entry
          in current.entries) {
        transaction.update(entry.key, <String, Object?>{
          'quantity': entry.value + quantities[entry.key.id]!,
          'status': 'inStock',
          'soldAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    SdLogger.info(LogTagConstant.order, 'Return committed', <String, Object>{
      'orderId': order.id,
      'restock': restock,
    });
  });

  Order _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      OrderDto.toEntity(doc, fallbackCurrency: _context.currency);
}

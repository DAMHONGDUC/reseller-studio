// `show`, because cloud_firestore exports an `Order` of its own and this
// file is about the app's.
import 'package:cloud_firestore/cloud_firestore.dart'
    show FieldValue, Timestamp;
import 'package:system_design/common.dart';

import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../dtos/order_dto.dart';

/// Orders, before anyone signs in (`docs/rules/GUEST_MODE.md`).
///
/// **The two multi-record writes keep the Firestore version's rules and drop
/// its concurrency guard.** A sale still refuses an item that is gone, sold or
/// archived — that is a business rule and a seller can hit it by having two
/// screens open. What is not reproduced is the read-everything-before-writing
/// dance: Firestore needs it because two devices can race, and a guest store
/// has exactly one writer.
class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository(LocalDatabase db, {required String currency})
    : _db = db,
      _items = LocalTable(db, db.localItems),
      _collection = LocalCollection<Order>(
        table: LocalTable(db, db.localOrders),
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
  final LocalTable _items;
  final LocalCollection<Order> _collection;

  @override
  Stream<List<Order>> watchOrders() => _collection.watchAll();

  @override
  Stream<Order?> watchOrder(String id) => _collection.watchOne(id);

  @override
  Future<Order?> findById(String id) => _collection.findById(id);

  @override
  Future<void> save(Order order) => _collection.save(order);

  @override
  Future<void> recordSale(Order order, List<Item> items) =>
      FailureMapper.guard('record sale', () async {
        // What each line was allocated, so an item's asking price is seeded
        // from its own share of a bundle rather than the whole payment.
        final Map<String, int> linePrice = <String, int>{
          for (final OrderLine line in order.lines)
            line.itemId: line.unitPrice.minor,
        };

        await _db.transaction(() async {
          final Map<String, Map<String, Object?>> read =
              <String, Map<String, Object?>>{};

          for (final Item item in items) {
            final LocalDocument? doc = await _items.findById(item.id);
            final Map<String, Object?> data =
                doc?.data ?? const <String, Object?>{};
            final int quantity = data['quantity'] is int
                ? data['quantity']! as int
                : item.quantity;
            final String status = data['status'] is String
                ? data['status']! as String
                : item.status.name;

            if (doc == null ||
                quantity <= 0 ||
                status == 'sold' ||
                status == 'archived') {
              throw StateError('Item ${item.id} is no longer sellable');
            }

            read[item.id] = data;
          }

          await _collection.save(order);

          for (final Item item in items) {
            final Map<String, Object?> data = read[item.id]!;
            final int quantity = data['quantity'] is int
                ? data['quantity']! as int
                : item.quantity;
            final int left = quantity - 1;

            await _items.put(item.id, item.createdAt, <String, Object?>{
              'quantity': left,
              'status': left == 0 ? 'sold' : 'inStock',
              if (left == 0) 'soldAt': Timestamp.fromDate(order.orderedAt),
              if (data['askingPriceMinor'] == null)
                'askingPriceMinor': linePrice[item.id] ?? order.salePrice.minor,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });

        SdLogger.info(
          LogTagConstant.order,
          'Sale committed locally',
          <String, Object>{'orderId': order.id, 'items': items.length},
        );
      });

  @override
  Future<void> closeReturn(Order order, {required bool restock}) =>
      FailureMapper.guard('close return', () async {
        final Map<String, int> quantities = <String, int>{};

        for (final OrderLine line in order.lines) {
          quantities.update(
            line.itemId,
            (int value) => value + line.quantity,
            ifAbsent: () => line.quantity,
          );
        }

        await _db.transaction(() async {
          await _collection.save(order);

          if (!restock) return;

          for (final MapEntry<String, int> entry in quantities.entries) {
            final LocalDocument? doc = await _items.findById(entry.key);

            if (doc == null) continue;

            final Object? raw = doc.data['quantity'];

            await _items.put(entry.key, DateTime.now(), <String, Object?>{
              'quantity': (raw is int ? raw : 0) + entry.value,
              'status': 'inStock',
              // Null rather than `FieldValue.delete()`: the local store reads
              // an absent field and an explicit null the same way, and there
              // is no way to tell one `FieldValue` from another off-server.
              'soldAt': null,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });

        SdLogger.info(
          LogTagConstant.order,
          'Return committed locally',
          <String, Object>{'orderId': order.id, 'restock': restock},
        );
      });
}

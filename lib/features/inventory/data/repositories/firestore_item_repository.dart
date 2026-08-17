import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../dtos/item_dto.dart';

/// Inventory, in Firestore.
///
/// **Soft deletes are filtered in memory, not in the query.** A
/// `where('deletedAt', isNull: true)` combined with an `orderBy` needs its own
/// composite index for every ordering the app uses, and deleted rows are a
/// rounding error in a seller's inventory — the read is cheaper than the four
/// indexes. It also keeps this repository's behaviour identical to the
/// in-memory one the screens are tested against.
class FirestoreItemRepository implements ItemRepository {
  const FirestoreItemRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Item>> watchItems() => FirestoreStream.collection(
    _context.collections.items.orderBy('createdAt', descending: true),
    _toEntity,
    operation: 'load inventory',
  ).map(_live);

  @override
  Stream<Item?> watchItem(String id) => FirestoreStream.document(
    _context.collections.items.doc(id),
    _toEntity,
    operation: 'load item',
  );

  @override
  Future<Item?> findById(String id) =>
      FailureMapper.guard('find item', () async {
        final DocumentSnapshot<Map<String, Object?>> doc = await _context
            .collections
            .items
            .doc(id)
            .get();

        return doc.exists ? _toEntity(doc) : null;
      });

  @override
  Stream<List<Item>> watchItemsForPurchase(String purchaseId) =>
      FirestoreStream.collection(
        _context.collections.items
            .where('purchaseId', isEqualTo: purchaseId)
            .orderBy('createdAt', descending: true),
        _toEntity,
        operation: 'load items for purchase',
      ).map(_live);

  @override
  Future<void> save(Item item) => FailureMapper.guard('save item', () async {
    await _context.collections.items
        .doc(item.id)
        .set(
          ItemDto.toMap(item, createdBy: _context.uid),
          SetOptions(merge: true),
        );

    SdLogger.info(LogTagConstant.item, 'Item saved', <String, Object>{
      'itemId': item.id,
      'status': item.status.name,
    });
  });

  @override
  Future<void> saveAll(List<Item> items) =>
      FailureMapper.guard('save items', () async {
        if (items.isEmpty) return;

        // One batch, not a loop of writes: hard rule 16 makes bulk a
        // first-class path, and forty round trips is the difference between
        // instant and a visible wait.
        final WriteBatch batch = _context.collections.items.firestore.batch();

        for (final Item item in items) {
          batch.set(
            _context.collections.items.doc(item.id),
            ItemDto.toMap(item, createdBy: _context.uid),
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        SdLogger.info(
          LogTagConstant.item,
          'Items saved in bulk',
          <String, Object>{'count': items.length},
        );
      });

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete item', () async {
        // Soft delete (hard rule 15): the row stays joinable by the orders and
        // purchases that reference it.
        await _context.collections.items.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        SdLogger.info(
          LogTagConstant.item,
          'Item soft-deleted',
          <String, Object>{'itemId': id},
        );
      });

  Item _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      ItemDto.toEntity(doc, fallbackCurrency: _context.currency);

  static List<Item> _live(List<Item> items) =>
      items.where((Item item) => !item.isDeleted).toList();
}

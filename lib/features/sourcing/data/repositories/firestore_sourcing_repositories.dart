import 'package:cloud_firestore/cloud_firestore.dart' hide Source;

import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/source.dart';
import '../../domain/repositories/sourcing_repository.dart';
import '../dtos/sourcing_dtos.dart';

/// Sources, in Firestore. Ordered by name — a seller picking one from a list
/// is looking for a shop they can name, not the one they added most recently.
class FirestoreSourceRepository implements SourceRepository {
  const FirestoreSourceRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Source>> watchSources() =>
      FirestoreStream.collection(
        _context.collections.sources.query.orderBy('name'),
        SourceDto.toEntity,
        operation: 'load sources',
      ).map(
        (List<Source> sources) =>
            sources.where((Source source) => !source.isDeleted).toList(),
      );

  @override
  Future<Source?> findById(String id) =>
      FailureMapper.guard('find source', () async {
        final DocumentSnapshot<Map<String, Object?>> doc = await _context
            .collections
            .sources
            .doc(id)
            .get();

        return doc.exists ? SourceDto.toEntity(doc) : null;
      });

  @override
  Future<void> save(Source source) =>
      FailureMapper.guard('save source', () async {
        await _context.collections.sources
            .doc(source.id)
            .set(
              SourceDto.toMap(source, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        SdLogger.info(LogTagConstant.sourcing, 'Source saved', <String, Object>{
          'sourceId': source.id,
        });
      });

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete source', () async {
        // Soft delete (hard rule 15) — hard-deleting a source orphans its
        // purchases and destroys the ROI history Sourcing exists to show.
        await _context.collections.sources.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        SdLogger.info(
          LogTagConstant.sourcing,
          'Source soft-deleted',
          <String, Object>{'sourceId': id},
        );
      });
}

/// Purchases, in Firestore.
class FirestorePurchaseRepository implements PurchaseRepository {
  const FirestorePurchaseRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Purchase>> watchPurchases() => FirestoreStream.collection(
    _context.collections.purchases.query.orderBy(
      'purchaseDate',
      descending: true,
    ),
    _toEntity,
    operation: 'load purchases',
  ).map(_live);

  @override
  Stream<List<Purchase>> watchPurchasesForSource(String sourceId) =>
      FirestoreStream.collection(
        _context.collections.purchases.query
            .where('sourceId', isEqualTo: sourceId)
            .orderBy('purchaseDate', descending: true),
        _toEntity,
        operation: 'load purchases for source',
      ).map(_live);

  @override
  Future<Purchase?> findById(String id) =>
      FailureMapper.guard('find purchase', () async {
        final DocumentSnapshot<Map<String, Object?>> doc = await _context
            .collections
            .purchases
            .doc(id)
            .get();

        return doc.exists ? _toEntity(doc) : null;
      });

  @override
  Future<void> save(Purchase purchase) => FailureMapper.guard(
    'save purchase',
    () async {
      await _context.collections.purchases
          .doc(purchase.id)
          .set(
            PurchaseDto.toMap(purchase, createdBy: _context.uid),
            SetOptions(merge: true),
          );

      SdLogger.info(LogTagConstant.sourcing, 'Purchase saved', <String, Object>{
        'purchaseId': purchase.id,
        'itemCount': purchase.itemCount,
      });
    },
  );

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete purchase', () async {
        await _context.collections.purchases.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        SdLogger.info(
          LogTagConstant.sourcing,
          'Purchase soft-deleted',
          <String, Object>{'purchaseId': id},
        );
      });

  Purchase _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      PurchaseDto.toEntity(doc, fallbackCurrency: _context.currency);

  static List<Purchase> _live(List<Purchase> purchases) =>
      purchases.where((Purchase purchase) => !purchase.isDeleted).toList();
}

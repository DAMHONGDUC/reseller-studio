import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/marketplace.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../dtos/marketplace_dto.dart';

/// The marketplaces one business sells on, in Firestore.
///
/// **Seller-owned data, not connection state.** The collection used to be
/// `allow write: if false` because it held OAuth status; connecting is dropped
/// (hard rule 10) and what lives here now is a list the seller maintains.
class FirestoreMarketplaceRepository implements MarketplaceRepository {
  const FirestoreMarketplaceRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Marketplace>> watchMarketplaces() => FirestoreStream.collection(
    _context.collections.marketplaces.orderBy('createdAt'),
    MarketplaceDto.toEntity,
    operation: 'load marketplaces',
  );

  @override
  Future<void> save(Marketplace marketplace) =>
      FailureMapper.guard('save marketplace', () async {
        await _context.collections.marketplaces
            .doc(marketplace.id)
            .set(
              MarketplaceDto.toMap(marketplace, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        SdLogger.info(
          LogTagConstant.marketplace,
          'Marketplace saved',
          <String, Object>{
            'marketplaceId': marketplace.id,
            'feePercent': marketplace.feeRate * 100,
          },
        );
      });

  @override
  Future<void> saveAll(List<Marketplace> marketplaces) =>
      FailureMapper.guard('seed marketplaces', () async {
        if (marketplaces.isEmpty) return;

        // One batch: an account left with two of its four starting marketplaces
        // has no way to tell that from a seller who deleted two.
        final WriteBatch batch = _context.collections.marketplaces.firestore
            .batch();

        for (final Marketplace marketplace in marketplaces) {
          batch.set(
            _context.collections.marketplaces.doc(marketplace.id),
            MarketplaceDto.toMap(marketplace, createdBy: _context.uid),
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        SdLogger.info(
          LogTagConstant.marketplace,
          'Marketplaces seeded',
          <String, Object>{'count': marketplaces.length},
        );
      });

  @override
  Future<void> delete(String marketplaceId) =>
      FailureMapper.guard('delete marketplace', () async {
        // Soft (hard rule 15): listings and orders name this by id, and a
        // hard delete would take it out of figures already reported.
        await _context.collections.marketplaces.doc(marketplaceId).set(
          <String, Object?>{
            'deletedAt': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        SdLogger.info(
          LogTagConstant.marketplace,
          'Marketplace deleted',
          <String, Object>{'marketplaceId': marketplaceId},
        );
      });
}

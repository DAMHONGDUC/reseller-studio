import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/supplier_product.dart';
import '../../domain/repositories/sourcing_repository.dart';
import '../dtos/supplier_product_dto.dart';

/// Supplier products, in Firestore.
class FirestoreSupplierProductRepository implements SupplierProductRepository {
  const FirestoreSupplierProductRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<SupplierProduct>> watchProducts() => FirestoreStream.collection(
    _context.collections.supplierProducts.query.orderBy('createdAt'),
    (DocumentSnapshot<Map<String, Object?>> doc) =>
        SupplierProductDto.toEntity(doc, fallbackCurrency: _context.currency),
    operation: 'load supplier products',
  );

  @override
  Future<void> save(SupplierProduct product) =>
      FailureMapper.guard('save supplier product', () async {
        await _context.collections.supplierProducts
            .doc(product.id)
            .set(_toMap(product), SetOptions(merge: true));
        SdLogger.info(
          LogTagConstant.dropship,
          'Supplier product saved',
          <String, Object>{
            'productId': product.id,
            'sourceId': product.sourceId,
            'itemId': product.itemId ?? '',
            'rank': product.rank,
          },
        );
      });

  @override
  Future<void> saveAll(List<SupplierProduct> products) =>
      FailureMapper.guard('save supplier products', () async {
        if (products.isEmpty) return;

        final WriteBatch batch = _context.collections.supplierProducts.firestore
            .batch();

        for (final SupplierProduct product in products) {
          batch.set(
            _context.collections.supplierProducts.doc(product.id),
            _toMap(product),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        SdLogger.info(
          LogTagConstant.dropship,
          'Supplier products saved in bulk',
          <String, Object>{'count': products.length},
        );
      });

  @override
  Future<void> delete(String productId) =>
      FailureMapper.guard('delete supplier product', () async {
        await _context.collections.supplierProducts.doc(productId).set(
          <String, Object?>{
            'deletedAt': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        SdLogger.info(
          LogTagConstant.dropship,
          'Supplier product deleted',
          <String, Object>{'productId': productId},
        );
      });

  Map<String, Object?> _toMap(SupplierProduct product) =>
      SupplierProductDto.toMap(
        product,
        currency: _context.currency,
        createdBy: _context.uid,
      );
}

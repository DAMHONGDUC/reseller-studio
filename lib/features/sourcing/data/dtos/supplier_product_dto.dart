import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/supplier_product.dart';

/// How a [SupplierProduct] is stored, in `supplier_products`. Its amounts
/// share one `currency` field: a supplier quotes in one currency.
final class SupplierProductDto {
  static SupplierProduct toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
    fallbackCurrency: fallbackCurrency,
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  static SupplierProduct fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return SupplierProduct(
      id: id,
      sourceId: FirestoreMapper.stringOrNull(data['sourceId']) ?? '',
      title: FirestoreMapper.stringOrNull(data['title']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      itemId: FirestoreMapper.stringOrNull(data['itemId']),
      rank: FirestoreMapper.intOrNull(data['rank']) ?? 1,
      url: FirestoreMapper.stringOrNull(data['url']),
      externalProductId: FirestoreMapper.stringOrNull(
        data['externalProductId'],
      ),
      externalVariantId: FirestoreMapper.stringOrNull(
        data['externalVariantId'],
      ),
      supplierPrice: FirestoreMapper.moneyOrNull(
        data['supplierPriceMinor'],
        currency,
      ),
      supplierShipping: FirestoreMapper.moneyOrNull(
        data['supplierShippingMinor'],
        currency,
      ),
      supplierTax: FirestoreMapper.moneyOrNull(
        data['supplierTaxMinor'],
        currency,
      ),
      shippingDays: FirestoreMapper.intOrNull(data['shippingDays']),
      stock: FirestoreMapper.intOrNull(data['stock']),
      lastCheckedAt: FirestoreMapper.dateOrNull(data['lastCheckedAt']),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    SupplierProduct product, {
    required String currency,
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'sourceId': product.sourceId,
    'title': product.title,
    'itemId': product.itemId,
    'rank': product.rank,
    'url': product.url,
    'externalProductId': product.externalProductId,
    'externalVariantId': product.externalVariantId,
    'currency': product.supplierPrice?.currency ?? currency,
    'supplierPriceMinor': FirestoreMapper.minorOrNull(product.supplierPrice),
    'supplierShippingMinor': FirestoreMapper.minorOrNull(
      product.supplierShipping,
    ),
    'supplierTaxMinor': FirestoreMapper.minorOrNull(product.supplierTax),
    'shippingDays': product.shippingDays,
    'stock': product.stock,
    'lastCheckedAt': _timestampOrNull(product.lastCheckedAt),
    'deletedAt': _timestampOrNull(product.deletedAt),
    'createdAt': Timestamp.fromDate(product.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/supplier_order.dart';
import '../../domain/enums/supplier_order_status.dart';

/// How a [SupplierOrder] is stored, in `supplier_orders`. Its amounts share
/// one `currency` field.
final class SupplierOrderDto {
  static SupplierOrder toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
    fallbackCurrency: fallbackCurrency,
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  static SupplierOrder fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return SupplierOrder(
      id: id,
      sourceId: FirestoreMapper.stringOrNull(data['sourceId']) ?? '',
      status:
          FirestoreMapper.enumOrNull(
            SupplierOrderStatus.values,
            data['status'],
          ) ??
          SupplierOrderStatus.placed,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      orderId: FirestoreMapper.stringOrNull(data['orderId']),
      itemId: FirestoreMapper.stringOrNull(data['itemId']),
      supplierProductId: FirestoreMapper.stringOrNull(
        data['supplierProductId'],
      ),
      externalSupplierOrderId: FirestoreMapper.stringOrNull(
        data['externalSupplierOrderId'],
      ),
      productCost: FirestoreMapper.moneyOrNull(
        data['productCostMinor'],
        currency,
      ),
      shippingCost: FirestoreMapper.moneyOrNull(
        data['shippingCostMinor'],
        currency,
      ),
      tax: FirestoreMapper.moneyOrNull(data['taxMinor'], currency),
      supplierRefund: FirestoreMapper.moneyOrNull(
        data['supplierRefundMinor'],
        currency,
      ),
      isSample: FirestoreMapper.boolOr(data['isSample'], fallback: false),
      trackingNumber: FirestoreMapper.stringOrNull(data['trackingNumber']),
      carrier: FirestoreMapper.stringOrNull(data['carrier']),
      placedAt: FirestoreMapper.dateOrNull(data['placedAt']),
      shippedAt: FirestoreMapper.dateOrNull(data['shippedAt']),
      deliveredAt: FirestoreMapper.dateOrNull(data['deliveredAt']),
      failureCode: FirestoreMapper.stringOrNull(data['failureCode']),
    );
  }

  static Map<String, Object?> toMap(
    SupplierOrder order, {
    required String currency,
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'sourceId': order.sourceId,
    'status': order.status.name,
    'orderId': order.orderId,
    'itemId': order.itemId,
    'supplierProductId': order.supplierProductId,
    'externalSupplierOrderId': order.externalSupplierOrderId,
    'currency': order.productCost?.currency ?? currency,
    'productCostMinor': FirestoreMapper.minorOrNull(order.productCost),
    'shippingCostMinor': FirestoreMapper.minorOrNull(order.shippingCost),
    'taxMinor': FirestoreMapper.minorOrNull(order.tax),
    'supplierRefundMinor': FirestoreMapper.minorOrNull(order.supplierRefund),
    'isSample': order.isSample,
    'trackingNumber': order.trackingNumber,
    'carrier': order.carrier,
    'placedAt': _timestampOrNull(order.placedAt),
    'shippedAt': _timestampOrNull(order.shippedAt),
    'deliveredAt': _timestampOrNull(order.deliveredAt),
    'failureCode': order.failureCode,
    'createdAt': Timestamp.fromDate(order.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}

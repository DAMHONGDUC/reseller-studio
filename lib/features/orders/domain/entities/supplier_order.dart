import '../../../../core/money/money.dart';
import '../enums/supplier_order_status.dart';

/// One order placed with a dropship supplier for one sold line
/// (`docs/DROPSHIPPING_PLAN.md`).
///
/// Its costs are facts — what the supplier charged and refunded — and they
/// become the sold line's cost, which is how a dropship sale's profit is
/// measured rather than guessed (hard rule 3).
class SupplierOrder {
  const SupplierOrder({
    required this.id,
    required this.sourceId,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.itemId,
    this.supplierProductId,
    this.externalSupplierOrderId,
    this.productCost,
    this.shippingCost,
    this.tax,
    this.supplierRefund,
    this.isSample = false,
    this.trackingNumber,
    this.carrier,
    this.placedAt,
    this.shippedAt,
    this.deliveredAt,
    this.failureCode,
  });

  final String id;

  /// The supplier, a `Source`.
  final String sourceId;
  final SupplierOrderStatus status;
  final DateTime createdAt;

  /// The sale this fulfils; null for a sample the seller bought themselves.
  final String? orderId;

  /// The order line it fulfils, by the item that line sold.
  final String? itemId;
  final String? supplierProductId;

  /// The supplier's own order number.
  final String? externalSupplierOrderId;

  final Money? productCost;
  final Money? shippingCost;
  final Money? tax;

  /// What the supplier gave back — a refund for a lost or faulty parcel.
  final Money? supplierRefund;

  /// Bought to check quality; its cost is an expense, not a sale's cost.
  final bool isSample;

  final String? trackingNumber;
  final String? carrier;
  final DateTime? placedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  /// Why a connected supplier refused it (Phase 4).
  final String? failureCode;

  SupplierOrder copyWith({
    SupplierOrderStatus? status,
    String? externalSupplierOrderId,
    Money? productCost,
    Money? shippingCost,
    Money? tax,
    Money? supplierRefund,
    String? trackingNumber,
    String? carrier,
    DateTime? placedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) => SupplierOrder(
    id: id,
    sourceId: sourceId,
    status: status ?? this.status,
    createdAt: createdAt,
    orderId: orderId,
    itemId: itemId,
    supplierProductId: supplierProductId,
    externalSupplierOrderId:
        externalSupplierOrderId ?? this.externalSupplierOrderId,
    productCost: productCost ?? this.productCost,
    shippingCost: shippingCost ?? this.shippingCost,
    tax: tax ?? this.tax,
    supplierRefund: supplierRefund ?? this.supplierRefund,
    isSample: isSample,
    trackingNumber: trackingNumber ?? this.trackingNumber,
    carrier: carrier ?? this.carrier,
    placedAt: placedAt ?? this.placedAt,
    shippedAt: shippedAt ?? this.shippedAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    failureCode: failureCode,
  );
}

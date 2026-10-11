import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/permissions/permission_blocked.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/system_permissions_provider.dart';
import '../../../../core/storage/document_picker.dart';
import '../../../../core/storage/file_uploader.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../sourcing/domain/entities/supplier_product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/supplier_order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/supplier_order_status.dart';
import '../../domain/services/supplier_orders.dart';
import 'order_actions_controller.dart';

/// Recording what happens to an order placed with a dropship supplier, by
/// hand (`docs/DROPSHIPPING_PLAN.md`, Phase 1).
///
/// Every write that changes what the supplier charged also re-costs the sold
/// line in the same commit, so the sale's profit is always measured from the
/// supplier order beside it (hard rule 3). True while a write is in flight.
class SupplierOrderController extends Notifier<bool> {
  @override
  bool build() => false;

  /// The seller placed [line]'s order at the supplier.
  Future<void> place({
    required Order order,
    required OrderLine line,
    required String sourceId,
    String? supplierProductId,
    String? supplierOrderNumber,
    Money? productCost,
    Money? shippingCost,
    Money? tax,
  }) {
    final DateTime now = DateTime.now();
    final SupplierOrder placed = SupplierOrder(
      id: SdId.unique(),
      sourceId: sourceId,
      status: SupplierOrderStatus.placed,
      createdAt: now,
      orderId: order.id,
      itemId: line.itemId,
      supplierProductId: supplierProductId,
      externalSupplierOrderId: supplierOrderNumber,
      productCost: productCost,
      shippingCost: shippingCost,
      tax: tax,
      placedAt: now,
    );

    return _write(
      'Place supplier order',
      placed,
      order: SupplierOrders.withLineCost(
        order,
        line.itemId,
        SupplierOrders.netCost(placed),
      ),
    );
  }

  /// The supplier shipped it. A sale still waiting to ship ships with it —
  /// the buyer's parcel is this one.
  Future<void> addTracking(
    SupplierOrder supplierOrder,
    Order order, {
    required String trackingNumber,
    String? carrier,
  }) async {
    await _write(
      'Add supplier tracking',
      supplierOrder.copyWith(
        status: SupplierOrderStatus.shipped,
        trackingNumber: trackingNumber,
        carrier: carrier,
        shippedAt: DateTime.now(),
      ),
    );
    if (order.status == OrderStatus.toShip) {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .markShipped(order, carrier: carrier, trackingNumber: trackingNumber);
    }
  }

  Future<void> markDelivered(SupplierOrder supplierOrder) => _write(
    'Supplier order delivered',
    supplierOrder.copyWith(
      status: SupplierOrderStatus.delivered,
      deliveredAt: DateTime.now(),
    ),
  );

  /// Called off before it shipped: the line has no cost again until a new
  /// supplier order is placed.
  Future<void> cancel(SupplierOrder supplierOrder, Order order) => _write(
    'Cancel supplier order',
    supplierOrder.copyWith(status: SupplierOrderStatus.cancelled),
    order: supplierOrder.itemId == null
        ? null
        : SupplierOrders.withLineCost(order, supplierOrder.itemId!, null),
  );

  /// The supplier gave [amount] back; the line's cost drops by it.
  Future<void> recordRefund(
    SupplierOrder supplierOrder,
    Order order,
    Money amount,
  ) {
    final SupplierOrder refunded = supplierOrder.copyWith(
      supplierRefund: amount,
    );

    return _write(
      'Record supplier refund',
      refunded,
      order: refunded.itemId == null
          ? null
          : SupplierOrders.withLineCost(
              order,
              refunded.itemId!,
              SupplierOrders.netCost(refunded),
            ),
    );
  }

  /// The seller bought one to check its quality. A sample is no sale's
  /// cost, so it lands as an expense beside the supplier order.
  Future<void> orderSample({
    required SupplierProduct product,
    required Money cost,
    String? supplierName,
  }) async {
    final DateTime now = DateTime.now();
    final SupplierOrder sample = SupplierOrder(
      id: SdId.unique(),
      sourceId: product.sourceId,
      status: SupplierOrderStatus.placed,
      createdAt: now,
      itemId: product.itemId,
      supplierProductId: product.id,
      productCost: cost,
      isSample: true,
      placedAt: now,
    );

    await _write('Order a sample', sample);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .save(
            Expense(
              id: SdId.unique(),
              category: ExpenseCategory.other,
              amount: cost,
              date: now,
              createdAt: now,
              vendor: supplierName,
              notes: product.title,
              supplierOrderId: sample.id,
            ),
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dropship,
        'Failed to record the sample as an expense',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'supplierOrderId': sample.id},
      );
      rethrow;
    }
  }

  /// Photograph or choose the supplier's invoice and keep it on the order.
  /// Null when the seller cancelled, which is not an error.
  Future<void> attachInvoice(
    SupplierOrder supplierOrder, {
    required bool fromCamera,
  }) async {
    final String? url;

    state = true;
    try {
      url = await DocumentPicker.pickAndUpload(
        uploader: ref.read(fileUploaderProvider),
        permissions: ref.read(systemPermissionsProvider),
        folder: FileFolder.receipts,
        recordId: supplierOrder.id,
        fromCamera: fromCamera,
      );
    } on PermissionBlocked {
      // Logged by the picker: a refusal is the seller's call, not a failure.
      rethrow;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dropship,
        'Failed to attach a supplier invoice',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'supplierOrderId': supplierOrder.id},
      );
      rethrow;
    } finally {
      state = false;
    }

    if (url == null) return;
    await _write(
      'Attach supplier invoice',
      supplierOrder.copyWith(invoiceUrl: url),
    );
  }

  Future<void> removeInvoice(SupplierOrder supplierOrder) => _write(
    'Remove supplier invoice',
    supplierOrder.copyWith(clearInvoiceUrl: true),
  );

  Future<void> _write(
    String describe,
    SupplierOrder supplierOrder, {
    Order? order,
  }) async {
    final Map<String, Object> data = <String, Object>{
      'supplierOrderId': supplierOrder.id,
      'orderId': supplierOrder.orderId ?? '',
      'status': supplierOrder.status.name,
      'recostsLine': order != null,
    };

    SdLogger.action(LogTagConstant.dropship, describe, data);
    state = true;

    try {
      await ref
          .read(supplierOrderRepositoryProvider)
          .save(supplierOrder, order: order);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dropship,
        'Failed to ${describe.toLowerCase()}',
        error: error,
        stackTrace: stackTrace,
        data: data,
      );
      rethrow;
    } finally {
      state = false;
    }
  }
}

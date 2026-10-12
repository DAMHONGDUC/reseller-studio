import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

/// Where an order placed with a dropship supplier is
/// (`docs/DROPSHIPPING_PLAN.md`).
///
/// "To order" is not a status: a sold dropship line with no supplier order is
/// a query, the way stale is (`SupplierOrders.toPlace`). Stored by [name].
enum SupplierOrderStatus {
  /// Asked of a connected supplier, not yet confirmed (Phase 4).
  requested,

  /// Placed and paid at the supplier.
  placed,

  /// The supplier shipped it and a tracking number exists.
  shipped,

  /// It reached the buyer.
  delivered,

  /// A connected supplier refused it (Phase 4).
  failed,

  /// Called off before it shipped.
  cancelled;

  /// Still on its way to the buyer.
  bool get isOpen =>
      this == SupplierOrderStatus.requested ||
      this == SupplierOrderStatus.placed ||
      this == SupplierOrderStatus.shipped;
}

/// How a supplier order status reads and which hue its badge wears.
extension SupplierOrderStatusDisplay on SupplierOrderStatus {
  String label(BuildContext context) => switch (this) {
    SupplierOrderStatus.requested => context.l10n.supplierOrderRequested,
    SupplierOrderStatus.placed => context.l10n.supplierOrderPlaced,
    SupplierOrderStatus.shipped => context.l10n.supplierOrderShipped,
    SupplierOrderStatus.delivered => context.l10n.supplierOrderDelivered,
    SupplierOrderStatus.failed => context.l10n.supplierOrderFailed,
    SupplierOrderStatus.cancelled => context.l10n.supplierOrderCancelled,
  };

  Color color(BuildContext context) => switch (this) {
    SupplierOrderStatus.requested => AppTagHue.grey,
    SupplierOrderStatus.placed => AppTagHue.blue,
    SupplierOrderStatus.shipped => AppTagHue.indigo,
    SupplierOrderStatus.delivered => AppTagHue.green,
    SupplierOrderStatus.failed => AppTagHue.red,
    SupplierOrderStatus.cancelled => AppTagHue.grey,
  }.of(context);
}

import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Where a dropship sale stands with its supplier — what the Supplier order
/// filter narrows by. An order with no dropship line has no stage.
enum OrderSupplierStage {
  /// A sold dropship line has no supplier order yet.
  toOrder,

  /// Ordered at the supplier, no tracking yet, within the wait allowed.
  awaitingTracking,

  /// Ordered at the supplier and waiting past the wait allowed.
  late,
}

extension OrderSupplierStageDisplay on OrderSupplierStage {
  String label(BuildContext context) => switch (this) {
    OrderSupplierStage.toOrder => context.l10n.supplierStageToOrder,
    OrderSupplierStage.awaitingTracking =>
      context.l10n.supplierStageAwaitingTracking,
    OrderSupplierStage.late => context.l10n.supplierStageLate,
  };
}

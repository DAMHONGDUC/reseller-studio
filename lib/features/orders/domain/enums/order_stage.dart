import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// The three moments an order passes through on its way to a known profit.
///
/// Read off an order by `OrderProgress`; never stored, because each one is
/// already a fact on the order (a ship date, a recorded payout).
enum OrderStage { sold, shipped, paidOut }

/// What a stage reads as on the order card's track.
///
/// Each reuses the word the app already uses for that fact elsewhere — the
/// sold status, the shipped status, the Paid out filter.
extension OrderStageDisplay on OrderStage {
  String label(BuildContext context) => switch (this) {
    OrderStage.sold => context.l10n.itemStatusSold,
    OrderStage.shipped => context.l10n.orderStatusShipped,
    OrderStage.paidOut => context.l10n.filterPayoutReceived,
  };
}

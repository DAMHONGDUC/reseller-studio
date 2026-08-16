import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/enums/order_status.dart';

/// The words for an order's status. `domain/` holds none (hard rule 7).
///
/// Two screens render this — the Orders list and the order detail — and they
/// used to carry a copy each. One switch, so a status can never read
/// differently in two places.
final class OrderStatusLabel {
  static String of(BuildContext context, OrderStatus status) =>
      switch (status) {
        OrderStatus.awaitingPayment => context.l10n.orderStatusAwaitingPayment,
        OrderStatus.toShip => context.l10n.orderStatusToShip,
        OrderStatus.shipped => context.l10n.orderStatusShipped,
        OrderStatus.delivered => context.l10n.orderStatusDelivered,
        OrderStatus.returnRequested => context.l10n.orderStatusReturnRequested,
        OrderStatus.returned => context.l10n.orderStatusReturned,
        OrderStatus.refunded => context.l10n.orderStatusRefunded,
        OrderStatus.cancelled => context.l10n.orderStatusCancelled,
      };
}

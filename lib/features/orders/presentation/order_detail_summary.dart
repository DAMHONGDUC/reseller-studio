import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/entities/order.dart';

/// The one line each folded section of Order detail shows
/// (`docs/UI_POLISH_PLAN.md`).
final class OrderDetailSummary {
  /// Carrier and tracking number, or that it has not shipped.
  static String shipping(BuildContext context, Order order) {
    final List<String> parts = <String>[
      if (order.carrier != null) order.carrier!,
      if (order.trackingNumber != null) order.trackingNumber!,
    ];

    return parts.isEmpty ? context.l10n.orderNotShippedYet : parts.join(' · ');
  }
}

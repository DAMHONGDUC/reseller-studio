import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../providers.dart';

/// The words on the Orders filter chips. The enum itself holds none, because
/// `providers.dart` has no `BuildContext` to read a translation with.
final class OrderFilterLabel {
  static String of(BuildContext context, OrderFilter filter) =>
      switch (filter) {
        OrderFilter.all => context.l10n.commonAll,
        OrderFilter.toShip => context.l10n.orderFilterToShip,
        OrderFilter.shipped => context.l10n.orderStatusShipped,
        OrderFilter.delivered => context.l10n.orderStatusDelivered,
        OrderFilter.returns => context.l10n.orderFilterReturns,
      };
}

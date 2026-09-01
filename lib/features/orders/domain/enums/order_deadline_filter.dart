import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../entities/order.dart';

/// What an order's shipping deadline says about it.
///
/// **Its own filter rather than a status**, for the same reason `stale` is not
/// an `ItemStatus`: overdue is a question about the clock, not a state an
/// order transitions into, and only an order still waiting to ship can be
/// late at all — `Order.isOverdue` is the one place that rule lives.
enum OrderDeadlineFilter {
  any,
  overdue,
  noDeadline;

  bool matches(Order order, {required DateTime now}) => switch (this) {
    OrderDeadlineFilter.any => true,
    // Null means the platform gave no deadline, which is not "on time".
    OrderDeadlineFilter.overdue => order.isOverdue(now) ?? false,
    OrderDeadlineFilter.noDeadline => order.shipByDate == null,
  };

  bool get isActive => this != OrderDeadlineFilter.any;
}

/// How a deadline filter is shown lives on the enum — owner's rule, the same
/// shape `ItemStatusDisplay` has.
extension OrderDeadlineFilterDisplay on OrderDeadlineFilter {
  String label(BuildContext context) => switch (this) {
    OrderDeadlineFilter.any => context.l10n.filterAny,
    OrderDeadlineFilter.overdue => context.l10n.orderFilterOverdue,
    OrderDeadlineFilter.noDeadline => context.l10n.orderFilterNoDeadline,
  };
}

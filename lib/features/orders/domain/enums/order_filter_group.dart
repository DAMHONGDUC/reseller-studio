import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// One question Orders' filter sheet asks, in the order it asks them.
///
/// The same single list `ItemFilterGroup` is for Inventory: the strip's chips
/// and both sheets read it.
enum OrderFilterGroup {
  status,
  marketplace,
  ordered,
  deadline,
  payout,
  tracking,
  saleRange,
}

/// How a group is titled lives on the enum — owner's rule.
extension OrderFilterGroupDisplay on OrderFilterGroup {
  String label(BuildContext context) => switch (this) {
    OrderFilterGroup.status => context.l10n.filterStatus,
    OrderFilterGroup.marketplace => context.l10n.filterMarketplace,
    OrderFilterGroup.ordered => context.l10n.filterOrdered,
    OrderFilterGroup.deadline => context.l10n.filterDeadline,
    OrderFilterGroup.payout => context.l10n.filterPayout,
    OrderFilterGroup.tracking => context.l10n.filterTracking,
    OrderFilterGroup.saleRange => context.l10n.filterSaleRange,
  };
}

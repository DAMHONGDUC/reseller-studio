import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../entities/item.dart';
import 'item_status.dart';

/// One option of Inventory's Status filter: every [ItemStatus], plus Stale.
///
/// **Stale is here and not on [ItemStatus]** because it is a query — on hand,
/// and listed long ago — never a state an item moves into. It joins the
/// group so a seller asks "where is it" in one place (`docs/rules/SCREENS.md`).
enum ItemStatusFilter {
  draft(ItemStatus.draft),
  inStock(ItemStatus.inStock),
  sold(ItemStatus.sold),
  archived(ItemStatus.archived),
  stale(null);

  const ItemStatusFilter(this.status);

  /// The status this option is, or null for the one that is a query.
  final ItemStatus? status;

  /// Whether [item] is under this option.
  bool matches(Item item, {required DateTime now}) => switch (status) {
    final ItemStatus status => item.status == status,
    null =>
      item.status.isOnHand &&
          StaleInventoryPolicy.isStale(item.listedAt, now: now),
  };
}

/// How an option reads lives on the enum — owner's rule. A status reads as
/// the status does everywhere else.
extension ItemStatusFilterDisplay on ItemStatusFilter {
  String label(BuildContext context) =>
      status?.label(context) ?? context.l10n.itemStale;
}

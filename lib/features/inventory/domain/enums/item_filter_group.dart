import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// One question Inventory's filter sheet asks, in the order it asks them.
///
/// **The strip's chips, the full sheet and a one-group sheet all read this
/// list**, so a new group cannot reach one of them without the others. The
/// Show preset is not here: it is `InventoryFilter`, held apart from the
/// criteria, and every reader puts it first.
enum ItemFilterGroup {
  status,
  condition,
  category,
  location,
  source,
  photos,
  cost,
  listed,
  added,
}

/// How a group is titled lives on the enum — owner's rule, the same shape
/// `ItemStatusDisplay` has.
extension ItemFilterGroupDisplay on ItemFilterGroup {
  String label(BuildContext context) => switch (this) {
    ItemFilterGroup.status => context.l10n.filterStatus,
    ItemFilterGroup.condition => context.l10n.itemCondition,
    ItemFilterGroup.category => context.l10n.filterCategory,
    ItemFilterGroup.location => context.l10n.filterLocation,
    ItemFilterGroup.source => context.l10n.filterSource,
    ItemFilterGroup.photos => context.l10n.filterPhotos,
    ItemFilterGroup.cost => context.l10n.filterCost,
    ItemFilterGroup.listed => context.l10n.filterListed,
    ItemFilterGroup.added => context.l10n.filterAdded,
  };
}

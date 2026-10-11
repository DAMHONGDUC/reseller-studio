import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

/// Who ships an item when it sells (`docs/DROPSHIPPING_PLAN.md`).
///
/// Stored by [name], so a case is never renamed once written.
enum ItemFulfilment {
  /// The seller holds it and ships it — every item before dropshipping.
  stocked,

  /// A supplier ships it straight to the buyer; the seller never holds it,
  /// so it has no shelf, no location and no cost until it is ordered.
  dropship,
}

/// How a fulfilment reads and which hue its tag wears.
extension ItemFulfilmentDisplay on ItemFulfilment {
  String label(BuildContext context) => switch (this) {
    ItemFulfilment.stocked => context.l10n.fulfilmentStocked,
    ItemFulfilment.dropship => context.l10n.fulfilmentDropship,
  };

  Color color(BuildContext context) => switch (this) {
    ItemFulfilment.stocked => AppTagHue.grey,
    ItemFulfilment.dropship => AppTagHue.violet,
  }.of(context);
}

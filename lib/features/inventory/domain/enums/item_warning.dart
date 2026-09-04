import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

/// A pair of fields on one item that cannot both be true.
///
/// **Shown, never refused** — owner's rule. Quantity and status are edited
/// freely and neither writes the other, so a seller can leave the record
/// saying two things at once; the app's job is to say so, not to argue with
/// the correction they came to make.
enum ItemWarning {
  /// On hand, with nothing on the shelf.
  emptyShelf,

  /// Sold, while the count says there are some left.
  soldWithStock,
}

/// **How a warning is shown lives on the warning** — owner's rule, the same
/// shape `ItemStatusDisplay` has: its words and its colour, so a value is
/// asked and there is exactly one answer.
extension ItemWarningDisplay on ItemWarning {
  String label(BuildContext context) => switch (this) {
    ItemWarning.emptyShelf => context.l10n.itemWarningEmptyShelf,
    ItemWarning.soldWithStock => context.l10n.itemWarningSoldWithStock,
  };

  /// **Amber for a gap, red for a contradiction.** Nothing on the shelf is a
  /// number nobody has entered yet; sold with stock left is the record
  /// disagreeing with itself, which is the one a seller has to resolve.
  Color color(BuildContext context) => switch (this) {
    ItemWarning.emptyShelf => AppTagHue.amber,
    ItemWarning.soldWithStock => AppTagHue.red,
  }.of(context);
}

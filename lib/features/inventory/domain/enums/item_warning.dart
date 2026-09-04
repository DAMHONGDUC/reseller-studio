import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';
import '../entities/item.dart';
import 'item_status.dart';

/// A pair of fields on one item that cannot both be true.
///
/// **Shown, never refused** — owner's rule. Quantity and status are edited
/// freely and neither writes the other, so a seller can leave the record
/// saying two things at once; the app's job is to say so, not to argue with
/// the correction they came to make.
enum ItemWarning {
  /// On hand — a draft or in stock — with nothing on the shelf.
  ///
  /// **"Sold with a count left" is not a sibling of this.** `quantity` is what
  /// was taken in and `Item.quantityOnHand` already reads zero off the shelf,
  /// so a sold row keeping its count is every sold item, not a contradiction.
  emptyShelf,
}

/// **How a warning is shown lives on the warning** — owner's rule, the same
/// shape `ItemStatusDisplay` has: its words and its colour, so a value is
/// asked and there is exactly one answer.
extension ItemWarningDisplay on ItemWarning {
  /// **It names both halves and asks for the fix** — owner's rule, and it is
  /// why the item comes with the context: "none on the shelf but status is In
  /// stock" tells the seller which two facts disagree, where "Check the count"
  /// tells them to go looking.
  String message(BuildContext context, Item item) => switch (this) {
    ItemWarning.emptyShelf => context.l10n.itemWarningEmptyShelf(
      item.status.label(context),
    ),
  };

  /// **Amber, not red.** A row on the shelf with no count is a number nobody
  /// has entered yet — a gap to fill rather than a claim that is false.
  Color color(BuildContext context) => switch (this) {
    ItemWarning.emptyShelf => AppTagHue.amber,
  }.of(context);
}

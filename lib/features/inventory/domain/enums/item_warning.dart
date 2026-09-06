import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
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
  /// The tag's words — what the inventory row has room for beside the date.
  ///
  /// **Short, because the row's job is to flag it while a seller scans forty**
  /// — owner's rule. The sentence that explains it is [message], and the
  /// screens with room for one draw that instead.
  String label(BuildContext context) => switch (this) {
    ItemWarning.emptyShelf => context.l10n.itemWarningEmptyShelfTag,
  };

  /// **It names both halves and asks for the fix** — owner's rule, and it is
  /// why the item comes with the context: "none on the shelf but status is In
  /// stock" tells the seller which two facts disagree, where "Check the count"
  /// tells them to go looking.
  String message(BuildContext context, Item item) => switch (this) {
    ItemWarning.emptyShelf => context.l10n.itemWarningEmptyShelf(
      item.status.label(context),
    ),
  };

  /// **The same red the count is drawn in** — owner's rule: one condition is
  /// one colour, and a figure meaning "something is wrong" takes the semantic
  /// token rather than a tag hue.
  Color color(BuildContext context) => switch (this) {
    ItemWarning.emptyShelf => context.sdTheme3.danger,
  };
}
